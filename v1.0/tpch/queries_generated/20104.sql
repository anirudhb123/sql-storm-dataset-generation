WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = (SELECT MIN(r_regionkey) FROM region)

    UNION ALL

    SELECT r.r_regionkey, r.r_name, r.r_comment, level + 1
    FROM region_hierarchy rh
    JOIN nation n ON rh.r_regionkey = n.n_regionkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE level < 10
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_spenders AS (
    SELECT c.custkey, c.name, c.total_spent
    FROM customer_orders c
    WHERE c.total_spent = (SELECT MAX(total_spent) FROM customer_orders)
    ORDER BY c.total_spent DESC
    LIMIT 5
),
unique_suppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_inner.ps_availqty) 
        FROM partsupp ps_inner
    )
)
SELECT 
    rh.r_name AS Region,
    COALESCE(ts.name, 'No Top Spender') AS Top_Spender,
    COALESCE(ts.total_spent, 0) AS Total_Spent,
    us.s_name AS Unique_Supplier,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Total_Sales
FROM region_hierarchy rh
LEFT JOIN top_spenders ts ON true
LEFT JOIN lineitem li ON li.l_shipmode = 'AIR' AND li.l_returnflag IS NULL
LEFT JOIN unique_suppliers us ON us.s_suppkey IN (
    SELECT DISTINCT ps.ps_suppkey 
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice < 100.00
)
WHERE rh.level <= 5
GROUP BY rh.r_name, ts.name, ts.total_spent, us.s_name
HAVING COUNT(DISTINCT li.l_orderkey) > 10
ORDER BY Total_Sales DESC
LIMIT 10;
