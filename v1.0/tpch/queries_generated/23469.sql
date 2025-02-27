WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 as Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
TotalPrice AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 100
)

SELECT 
    p.p_name,
    p.p_brand,
    s.s_name,
    CASE 
        WHEN SUP.Level IS NULL THEN 'Outside Supplier'
        ELSE 'Local Supplier Level ' || SUP.Level
    END AS supplier_status,
    COALESCE(tp.total_revenue, 0) AS total_revenue,
    COALESCE(HVO.o_totalprice, 0) AS high_value_order_price,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_tax IS NOT NULL AND l.l_discount IS NOT NULL) as tax_discounted_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COALESCE(tp.total_revenue, 0) DESC) AS revenue_rank
FROM part p
LEFT JOIN SupplierHierarchy SUP ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = SUP.s_suppkey)
LEFT JOIN TotalPrice tp ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = tp.o_orderkey)
LEFT JOIN HighValueOrders HVO ON tp.o_orderkey = HVO.o_orderkey
LEFT JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
WHERE p.p_retailprice IS NOT NULL
AND (p.p_size BETWEEN 1 AND 10 OR p.p_type LIKE '%box%')
ORDER BY supplier_status, total_revenue DESC;
