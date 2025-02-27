WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           ROUND(SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey), 2) AS total_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty + 1,
           ROUND(SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey), 2)
    FROM partsupp ps
    JOIN SupplyCostCTE cte ON ps.ps_partkey = cte.ps_partkey
    WHERE cte.ps_availqty < 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
MaxCustomerSpent AS (
    SELECT MAX(total_spent) AS max_spent
    FROM CustomerOrders
)
SELECT p.p_partkey, p.p_name, p.p_retailprice,
       COALESCE(MAX(s.total_cost), 0) AS max_supply_cost,
       CASE WHEN co.order_count IS NOT NULL THEN 'Active' ELSE 'Inactive' END AS customer_status,
       CASE WHEN p.p_size IS NULL THEN 'Unknown Size' ELSE CAST(p.p_size AS VARCHAR) END AS part_size,
       STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names
FROM part p
LEFT JOIN SupplyCostCTE s ON p.p_partkey = s.ps_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
FULL OUTER JOIN (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey
) co ON ps.ps_suppkey = co.c_custkey
JOIN nation n ON n.n_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_regionkey IN (
        SELECT r.r_regionkey 
        FROM region r 
        WHERE r.r_name LIKE '%East%'
    )
    LIMIT 1
)
WHERE (s.ps_availqty IS NULL OR s.ps_availqty > 5)
  AND (p.p_comment LIKE '%special%' OR p.p_retailprice < (SELECT max_spent FROM MaxCustomerSpent))
GROUP BY p.p_partkey, p.p_name, p.p_retailprice, co.order_count, p.p_size
ORDER BY max_supply_cost DESC, p.p_name ASC;
