
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    
    UNION ALL
    
    SELECT 
        sh.c_custkey,
        sh.c_name,
        SUM(o.o_totalprice) AS total_spent,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 500)
    GROUP BY 
        sh.c_custkey, sh.c_name, sh.level
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_revenue,
    CASE 
        WHEN COUNT(o.o_orderkey) > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS order_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND s.s_acctbal IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY 
    discounted_revenue DESC
FETCH FIRST 10 ROWS ONLY;
