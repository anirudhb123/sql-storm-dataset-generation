WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        supplier_hierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#12' AND p.p_size BETWEEN 10 AND 20 ORDER BY p.p_retailprice DESC LIMIT 1)
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        sh.level < 3
),

customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice > 5000
)

SELECT 
    sh.s_name AS supplier_name,
    MAX(sh.s_acctbal) AS max_supplier_balance,
    COALESCE(c.c_name, 'No Orders') AS customer_name,
    COUNT(co.o_orderkey) AS order_count,
    SUM(co.o_totalprice) AS total_spent,
    STRING_AGG(CASE WHEN co.recent_order = 1 THEN 'Recent Order' ELSE 'Old Order' END, ', ') AS order_status
FROM 
    supplier_hierarchy sh
LEFT JOIN 
    customer_orders co ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_size = 15 AND p.p_container IS NOT NULL LIMIT 1))
GROUP BY 
    sh.s_name, c.c_name
HAVING 
    MAX(sh.s_acctbal) - COALESCE(SUM(co.o_totalprice), 0) > 3000
ORDER BY 
    max_supplier_balance DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY
