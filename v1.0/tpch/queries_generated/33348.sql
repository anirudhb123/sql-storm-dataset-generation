WITH RECURSIVE Region_CTE AS (
    SELECT r_regionkey, r_name, r_comment, 1 AS level
    FROM region
    WHERE r_name IS NOT NULL
    UNION ALL
    SELECT r.regionkey, r.r_name, r.r_comment, c.level + 1
    FROM region r
    JOIN Region_CTE c ON r.r_regionkey = c.r_regionkey
), 
Supplier_Agg AS (
    SELECT s_nationkey, COUNT(s_suppkey) AS supplier_count, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    GROUP BY s_nationkey
), 
Nation_Max AS (
    SELECT n.n_nationkey, n.n_name, MAX(s.total_acctbal) AS max_acctbal
    FROM nation n
    JOIN Supplier_Agg s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
LineItem_Summary AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    COALESCE(ls.total_sales, 0) AS total_sales,
    COALESCE(ls.total_quantity, 0) AS total_quantity,
    nm.n_name,
    nm.max_acctbal,
    CASE 
        WHEN nm.max_acctbal IS NULL THEN 'No Supplier'
        ELSE 'Has Supplier'
    END AS supplier_status
FROM part p
LEFT JOIN LineItem_Summary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN Nation_Max nm ON nm.n_nationkey = (
    SELECT s_nationkey 
    FROM supplier 
    WHERE s_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp ps 
        WHERE ps_partkey = p.p_partkey
    ) 
    LIMIT 1
)
ORDER BY total_sales DESC, p.p_partkey ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
