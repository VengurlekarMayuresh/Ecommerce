const { BlobServiceClient } = require('@azure/storage-blob');
const { v4: uuidv4 } = require('uuid');

let blobServiceClient;
let containerClient;

const CONTAINER_NAME = 'product-images';

// Initialize Azure Blob Storage
function initializeBlobStorage() {
  const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
  
  if (!connectionString) {
    console.warn('Azure Storage connection string not set. Using Cloudinary fallback.');
    return false;
  }

  try {
    blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
    containerClient = blobServiceClient.getContainerClient(CONTAINER_NAME);
    console.log('Azure Blob Storage initialized successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize Azure Blob Storage:', error.message);
    return false;
  }
}

// Create container if it doesn't exist
async function ensureContainerExists() {
  try {
    const createContainerResponse = await containerClient.createIfNotExists({
      access: 'blob' // Public read access for blobs
    });
    
    if (createContainerResponse.succeeded) {
      console.log(`Container "${CONTAINER_NAME}" created successfully`);
    } else {
      console.log(`Container "${CONTAINER_NAME}" already exists`);
    }
    return true;
  } catch (error) {
    console.error('Error ensuring container exists:', error.message);
    return false;
  }
}

// Upload image to Azure Blob Storage
async function uploadImage(file) {
  if (!containerClient) {
    throw new Error('Blob Storage not initialized');
  }

  try {
    // Generate unique blob name
    const blobName = `${uuidv4()}-${file.originalname}`;
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);

    // Set content type
    const options = {
      blobHTTPHeaders: {
        blobContentType: file.mimetype
      }
    };

    // Upload file
    await blockBlobClient.uploadData(file.buffer, options);

    // Return public URL
    const imageUrl = blockBlobClient.url;
    
    return {
      success: true,
      url: imageUrl,
      blobName: blobName
    };
  } catch (error) {
    console.error('Error uploading image:', error.message);
    throw error;
  }
}

// Delete image from Azure Blob Storage
async function deleteImage(blobName) {
  if (!containerClient) {
    throw new Error('Blob Storage not initialized');
  }

  try {
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
    await blockBlobClient.deleteIfExists();
    
    return {
      success: true,
      message: 'Image deleted successfully'
    };
  } catch (error) {
    console.error('Error deleting image:', error.message);
    throw error;
  }
}

// Get SAS URL for private access (if needed)
async function generateSasUrl(blobName, expiryMinutes = 60) {
  const { BlobSASPermissions, generateBlobSASQueryParameters } = require('@azure/storage-blob');
  
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  
  const sasOptions = {
    containerName: CONTAINER_NAME,
    blobName: blobName,
    permissions: BlobSASPermissions.parse("r"), // Read only
    startsOn: new Date(),
    expiresOn: new Date(new Date().valueOf() + expiryMinutes * 60 * 1000)
  };

  const sasToken = generateBlobSASQueryParameters(
    sasOptions,
    blobServiceClient.credential
  ).toString();

  return `${blockBlobClient.url}?${sasToken}`;
}

module.exports = {
  initializeBlobStorage,
  ensureContainerExists,
  uploadImage,
  deleteImage,
  generateSasUrl
};
