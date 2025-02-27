
SELECT c_city, COUNT(*) AS num_customers 
FROM customer_address 
GROUP BY c_city 
ORDER BY num_customers DESC 
LIMIT 10;
