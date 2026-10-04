// counter.js

// We will replace this placeholder URL with your actual AWS API Gateway endpoint once we deploy it using Terraform.
const apiUrl = 'https://your-api-id.execute-api.region.amazonaws.com/prod/count';
const api_url = "https://xe46aq313i.execute-api.ap-south-1.amazonaws.com/prod/count";
async function updateVisitorCount() {
    try {
        // Fetch the data from your Python Lambda backend
        const response = await fetch(apiUrl);
        
        // Convert the response into a JavaScript object
        const data = await response.json();
        
        // Target the span ID in our HTML and inject the number
        document.getElementById('visitor-count').innerText = data.count;
        
    } catch (error) {
        // If the API fails or hasn't been deployed yet, fail gracefully
        console.error('Error fetching visitor count:', error);
        document.getElementById('visitor-count').innerText = 'Unavailable';
    }
}

// Execute the function when the script loads
updateVisitorCount();