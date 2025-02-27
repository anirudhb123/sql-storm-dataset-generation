WITH RECURSIVE supplier_rank AS (
    SELECT s_suppkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
), part_info AS (
    SELECT p_partkey, p_retailprice, p_size, 
           CASE 
               WHEN p_size < 10 THEN 'Small'
               WHEN p_size BETWEEN 10 AND 20 THEN 'Medium'
               ELSE 'Large' 
           END AS size_category
    FROM part
), revenue AS (
    SELECT l_partkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY l_partkey
), nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, 
           SUM(CASE WHEN sr.rank = 1 THEN sr.s_acctbal ELSE 0 END) AS top_supplier_balance
    FROM nation n
    JOIN supplier_rank sr ON n.n_nationkey = sr.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    pi.size_category,
    ns.n_name,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
    COALESCE(SUM(r.total_revenue), 0) AS total_revenue,
    AVG(CASE WHEN sr.rank <= 2 THEN sr.s_acctbal END) AS avg_top_balances
FROM 
    part_info pi
LEFT JOIN 
    partsupp ps ON pi.p_partkey = ps.ps_partkey
LEFT JOIN 
    revenue r ON pi.p_partkey = r.l_partkey
JOIN 
    nation_supplier ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'ASIA' LIMIT 1)
LEFT JOIN 
    supplier_rank sr ON sr.s_suppkey = ps.ps_suppkey
WHERE 
    pi.p_retailprice > ALL (
        SELECT AVG(p_retailprice)
        FROM part
        WHERE p_size > 5
    ) AND pi.size_category IS NOT NULL
GROUP BY 
    pi.size_category, ns.n_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > CASE WHEN SUM(COALESCE(r.total_revenue, 0)) = 0 THEN 1 ELSE 0 END
ORDER BY 
    unique_parts DESC, total_revenue DESC;
