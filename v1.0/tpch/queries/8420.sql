WITH supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT sp.s_suppkey) AS total_suppliers,
    SUM(sp.ps_availqty) AS total_available_quantity,
    SUM(CASE WHEN cos.order_count > 5 THEN cos.total_spent ELSE 0 END) AS high_spender_total
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier_part_info sp ON sp.s_suppkey = (
        SELECT 
            s.s_suppkey 
        FROM 
            supplier s 
        WHERE 
            s.s_nationkey = n.n_nationkey
        LIMIT 1
    )
LEFT JOIN 
    customer_order_summary cos ON cos.c_custkey IN (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderstatus = 'O'
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_suppliers DESC, high_spender_total DESC;
