import logging
import os
from datetime import datetime

# Set up logging directory
LOG_DIR = 'logs'
os.makedirs(LOG_DIR, exist_ok=True)

# Configure logging
log_file = os.path.join(LOG_DIR, f'app_{datetime.now().strftime("%Y%m%d")}.log')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)

# Create a logger
logger = logging.getLogger(__name__)

# Example usage
if __name__ == '__main__':
    logger.info('Logger initialized.')
    logger.error('This is an error message.')
    logger.warning('This is a warning message.')
    logger.info('This is an info message.') 