WITH RECURSIVE CTE_Orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) as rn
    FROM orders
    WHERE o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
    AND EXISTS (
        SELECT 1 FROM customer 
        WHERE c_custkey = o_custkey AND c_acctbal IS NOT NULL
    )
),
CTE_Supplier_Summary AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_availqty) as total_available,
           SUM(ps_supplycost) as total_supply_cost,
           COUNT(DISTINCT ps_suppkey) as supplier_count
    FROM partsupp
    GROUP BY ps_partkey
),
CTE_Customer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Unknown'
               ELSE c.c_mktsegment
           END AS mktsegment_type,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) as rn
    FROM customer c
    WHERE c.c_acctbal > 0
)
SELECT 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, 
    region.r_name AS supplier_region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    (SELECT AVG(o_totalprice) FROM CTE_Orders) AS avg_order_value,
    (SELECT COUNT(*) FROM CTE_Customer WHERE rn <= 5) AS top_customers,
    CASE 
        WHEN COUNT(DISTINCT s.s_suppkey) > 5 THEN 'Diverse'
        ELSE 'Niche'
    END AS supplier_diversity
FROM part p
JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN (
    SELECT n.n_regionkey, n.n_name 
    FROM nation n 
    JOIN region r ON n.n_regionkey = r.r_regionkey
) region ON s.s_nationkey = region.n_regionkey
JOIN CTE_Orders o ON l.l_orderkey = o.o_orderkey
WHERE p.p_size > (SELECT AVG(p_size) FROM part)
  AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
  AND (p.p_retailprice BETWEEN 100.00 AND 500.00 OR p.p_retailprice IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, region.r_name
HAVING total_revenue > (SELECT AVG(total_supply_cost) FROM CTE_Supplier_Summary)
   OR EXISTS (SELECT 1 FROM CTE_Customer c WHERE c.rn = 1 AND c.c_acctbal > 1000)
ORDER BY total_revenue DESC
LIMIT 10;
