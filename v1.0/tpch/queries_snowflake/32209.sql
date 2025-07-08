
WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        1 AS depth
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        depth + 1
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        p.p_retailprice > 20.00
)

SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS finished_order_total,
    AVG(o.o_totalprice) AS average_order_value,
    LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY AVG(o.o_totalprice) DESC) AS rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    (n.n_comment LIKE '%supplier%' OR n.n_name IS NOT NULL)
    AND (l.l_shipdate >= '1997-01-01' OR l.l_shipdate IS NULL)
GROUP BY 
    r.r_name
HAVING 
    AVG(o.o_totalprice) > 1000.00
ORDER BY 
    nation_count DESC, average_order_value ASC
;