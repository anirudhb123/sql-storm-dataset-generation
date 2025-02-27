
SELECT c_city, COUNT(*) as customer_count
FROM customer_address
GROUP BY c_city
ORDER BY customer_count DESC
LIMIT 10;
