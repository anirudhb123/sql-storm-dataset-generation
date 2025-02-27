WITH RECURSIVE PriceSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        (p.p_retailprice * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0

    UNION ALL

    SELECT 
        ps.ps_partkey,
        NULL,
        NULL,
        SUM(ps.ps_availqty) AS ps_availqty,
        SUM(p.p_retailprice * ps.ps_availqty) AS total_value
    FROM 
        PriceSummary ps
    JOIN 
        part p ON p.p_partkey = ps.p_partkey
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(CASE 
        WHEN o.o_totalprice IS NOT NULL THEN o.o_totalprice 
        ELSE 0 
    END) AS avg_order_value,
    SUM(w.total_value) AS total_value,
    ROUND((COUNT(DISTINCT c.c_custkey) * 1.0 / NULLIF(SUM(w.total_value), 0)), 2) AS cust_value_ratio
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    PriceSummary w ON w.p_partkey = ANY(SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_value DESC;
