WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey < oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
DetailedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_discount, l.l_extendedprice,
           p.p_brand, p.p_name, ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) as rn
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE l.l_discount BETWEEN 0.05 AND 0.07
)
SELECT 
    ch.c_custkey, 
    ch.c_name, 
    CONCAT('Total Spent: $', ROUND(co.total_spent, 2)) AS spending_summary,
    COUNT(DISTINCT d.l_orderkey) AS order_count,
    SUM(d.l_extendedprice * (1 - d.l_discount)) AS total_value,
    MAX(d.l_quantity) AS max_quantity,
    MIN(d.l_discount) AS min_discount,
    COUNT(d.l_partkey) AS total_items
FROM CustomerOrders co
JOIN customer ch ON co.c_custkey = ch.c_custkey
LEFT JOIN DetailedLineItems d ON d.l_orderkey IN (SELECT o.o_orderkey FROM OrderHierarchy oh JOIN orders o ON o.o_orderkey = oh.o_orderkey)
GROUP BY ch.c_custkey, ch.c_name
HAVING total_value > (SELECT AVG(total_spent) FROM CustomerOrders) 
   OR (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = ch.c_custkey AND o.o_orderstatus = 'O') > 5
ORDER BY total_value DESC;
