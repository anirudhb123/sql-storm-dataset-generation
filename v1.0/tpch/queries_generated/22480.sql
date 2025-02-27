WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE 
        sh.level < 5
),

customer_orders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey
),

part_supplier_summary AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_availqty) AS total_avail,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)

SELECT 
    r.r_name, 
    SUM(COALESCE(co.order_count, 0)) AS total_orders,
    SUM(COALESCE(ps.total_avail, 0)) AS available_parts,
    COUNT(DISTINCT sh.s_suppkey) AS active_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer_orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN 
    part_supplier_summary ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
LEFT JOIN 
    supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE 
    r.r_name NOT LIKE 'A%' 
    AND (sh.level IS NULL OR sh.level > 2)
GROUP BY 
    r.r_name
HAVING 
    SUM(COALESCE(co.total_spent, 0)) > (SELECT AVG(total_spent) FROM customer_orders)
ORDER BY 
    total_orders DESC, available_parts ASC;
