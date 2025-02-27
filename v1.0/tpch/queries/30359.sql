WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal <= 1000
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopRegions AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= DATE '1997-01-01'
    GROUP BY r.r_name
    ORDER BY total_sales DESC
    LIMIT 5
)
SELECT 
    p.p_name, 
    p.p_brand, 
    COALESCE(avg_l.extended_price_avg, 0) AS avg_extended_price,
    COALESCE(total_cost.total_cost, 0) AS total_supply_cost,
    th.r_name AS region_name,
    sh.level AS supplier_level
FROM 
    part p
LEFT JOIN (
    SELECT l.l_partkey, AVG(l.l_extendedprice) AS extended_price_avg
    FROM lineitem l
    WHERE l.l_discount > 0.05
    GROUP BY l.l_partkey
) avg_l ON p.p_partkey = avg_l.l_partkey
LEFT JOIN PartSupplier total_cost ON p.p_partkey = total_cost.ps_partkey
JOIN TopRegions th ON th.total_sales > 10000
LEFT JOIN SupplierHierarchy sh ON sh.s_acctbal = total_cost.total_cost
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND (p.p_comment LIKE '%special%' OR p.p_comment IS NULL)
ORDER BY 
    th.total_sales DESC, 
    avg_l.extended_price_avg DESC;