WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty,
           ps_supplycost, 1 AS recursion_level
    FROM partsupp
    WHERE ps_availqty IS NOT NULL
    UNION ALL
    SELECT ps.partkey, ps.suppkey, ps.availqty,
           ps.supplycost * 1.05, recursion_level + 1
    FROM partsupp ps
    JOIN SupplyCostCTE scte ON ps.ps_partkey = scte.ps_partkey
    WHERE recursion_level < 5
), 
CustomerOrderSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
SizePrice AS (
    SELECT p.p_size, AVG(p.p_retailprice) AS avg_price
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps
                       WHERE ps.ps_availqty > 100)
    GROUP BY p.p_size
)
SELECT n.n_name, COALESCE(SUM(scte.ps_supplycost * scte.ps_availqty), 0) AS total_supply_cost,
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(CASE WHEN cos.total_orders > 0 THEN cos.total_price ELSE NULL END) AS total_ordered_revenue,
       STRING_AGG(DISTINCT CONCAT(p.p_brand, ' - ', p.p_name), ', ') AS part_details
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplyCostCTE scte ON scte.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerOrderSummary cos ON cos.c_custkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = scte.ps_partkey
WHERE (n.n_name IS NOT NULL OR n.n_name = 'Asia')
GROUP BY n.n_name
HAVING COUNT(DISTINCT p.p_partkey) > (SELECT AVG(avg_size) FROM (SELECT p_size AS avg_size FROM part GROUP BY p_size) AS avg_size_tbl)
ORDER BY total_supply_cost DESC, customer_count ASC;
