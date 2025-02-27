WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           COALESCE(NULLIF(s.s_comment, 'Unspecified'), 'General Comment') AS comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
      
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           COALESCE(NULLIF(s.s_comment, 'Unspecified'), 'General Comment') AS comment
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_suppkey = cte.s_suppkey + 1 
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
, PartInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_per_type
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
)
SELECT
    p.p_name,
    p.total_avail_qty,
    s.nation_name,
    s.comment AS supplier_comment,
    CASE 
        WHEN p.total_avail_qty IS NULL THEN 'No Quantity Available'
        ELSE CONCAT('Available Quantity: ', CAST(p.total_avail_qty AS VARCHAR))
    END AS availability_status,
    COUNT(o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_shipdate
FROM PartInfo p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN SupplierCTE s ON s.s_suppkey = l.l_suppkey
WHERE s.nation_name IS NOT NULL
AND (p.p_name LIKE '%Widget%' OR p.p_name LIKE '%Gadget%')
AND rank_per_type < 10
GROUP BY p.p_name, p.total_avail_qty, s.nation_name, s.comment
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY p.total_avail_qty DESC NULLS LAST;