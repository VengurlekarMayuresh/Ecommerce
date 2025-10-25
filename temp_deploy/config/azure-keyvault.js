const { DefaultAzureCredential } = require("@azure/identity");
const { SecretClient } = require("@azure/keyvault-secrets");

// Azure Key Vault URL - set this in your environment variables
const keyVaultName = process.env.KEY_VAULT_NAME;
const KVUri = `https://${keyVaultName}.vault.azure.net`;

let secretClient;

// Initialize Key Vault client
function initializeKeyVault() {
  if (!keyVaultName) {
    console.warn('KEY_VAULT_NAME not set. Using environment variables directly.');
    return null;
  }

  try {
    const credential = new DefaultAzureCredential();
    secretClient = new SecretClient(KVUri, credential);
    console.log('Azure Key Vault initialized successfully');
    return secretClient;
  } catch (error) {
    console.error('Failed to initialize Key Vault:', error.message);
    return null;
  }
}

// Get secret from Key Vault
async function getSecret(secretName) {
  if (!secretClient) {
    // Fallback to environment variable
    return process.env[secretName];
  }

  try {
    const secret = await secretClient.getSecret(secretName);
    return secret.value;
  } catch (error) {
    console.warn(`Failed to get secret ${secretName} from Key Vault:`, error.message);
    // Fallback to environment variable
    return process.env[secretName];
  }
}

// Load all secrets at startup
async function loadSecrets() {
  initializeKeyVault();

  const secrets = {
    MONGO_URI: await getSecret('MONGO-URI'),
    SECRET_KEY: await getSecret('JWT-SECRET-KEY'),
    CLOUDINARY_CLOUD_NAME: await getSecret('CLOUDINARY-CLOUD-NAME'),
    CLOUDINARY_API_KEY: await getSecret('CLOUDINARY-API-KEY'),
    CLOUDINARY_API_SECRET: await getSecret('CLOUDINARY-API-SECRET'),
    PAYPAL_CLIENT_ID: await getSecret('PAYPAL-CLIENT-ID'),
    PAYPAL_CLIENT_SECRET: await getSecret('PAYPAL-CLIENT-SECRET'),
    PAYPAL_MODE: await getSecret('PAYPAL-MODE')
  };

  return secrets;
}

module.exports = {
  initializeKeyVault,
  getSecret,
  loadSecrets
};
