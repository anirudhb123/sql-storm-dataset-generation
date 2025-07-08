
WITH supplier_rank AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as rank
    FROM 
        supplier
), 
part_supplier AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
) 
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(MAX(l.l_quantity), 0) AS max_lineitem_quantity,
    AVG(sr.s_acctbal) FILTER (WHERE sr.rank <= 3) AS avg_top_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS distinct_order_count,
    COUNT(*) OVER (PARTITION BY p.p_partkey) AS part_order_count,
    CASE 
        WHEN MAX(l.l_extendedprice) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    part p
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier_rank sr ON sr.s_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey = p.p_partkey
    )
LEFT JOIN 
    part_supplier ps ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 500.00 
    AND p.p_size IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, sr.s_acctbal, sr.rank
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0 
    OR AVG(sr.s_acctbal) IS NOT NULL
ORDER BY 
    sales_status DESC, avg_top_supplier_balance DESC;
