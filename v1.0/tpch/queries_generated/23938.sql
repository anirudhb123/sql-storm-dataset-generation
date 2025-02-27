WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        CASE
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            WHEN s.s_acctbal > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS acctbal_status
    FROM
        supplier s
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (SELECT AVG(ps.ps_supplycost) 
         FROM partsupp ps
         WHERE ps.ps_partkey = p.p_partkey
         HAVING COUNT(ps.ps_suppkey) > 0) AS avg_supplycost,
        CASE
            WHEN p.p_container LIKE '%BOX%' THEN 'Boxed'
            WHEN p.p_retailprice < 10 THEN 'Cheap'
            ELSE 'Expensive'
        END AS pricing_category
    FROM
        part p
    WHERE
        p.p_size IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment LIKE '%%')
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(p.p_partkey) FILTER (WHERE p.pricing_category = 'Boxed') AS boxed_parts_count,
    AVG(r.s_acctbal) AS avg_supplier_acctbal,
    MIN(COALESCE(rs.acctbal_status, 'Unclassified')) AS supplier_acct_status
FROM
    orders o
JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN FilteredParts p ON li.l_partkey = p.p_partkey
JOIN RankedSuppliers rs ON rs.s_suppkey = li.l_suppkey
JOIN nation n ON n.n_nationkey = rs.s_nationkey
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND li.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
    AND (p.avg_supplycost IS NULL OR p.avg_supplycost < 50 OR p.p_retailprice IS NULL)
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;
