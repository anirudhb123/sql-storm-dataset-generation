WITH part_supplier_summary AS (
    SELECT 
        p.p_name, 
        s.s_name, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', ps.ps_availqty, ' units at a cost of $', ps.ps_supplycost) AS summary
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
customer_order_summary AS (
    SELECT 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent,
        CONCAT(c.c_name, ' has placed ', COUNT(o.o_orderkey), ' orders totaling $', SUM(o.o_totalprice)) AS order_summary
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    p.s_name, 
    p.p_name, 
    p.ps_availqty, 
    p.ps_supplycost, 
    c.c_name,
    c.total_orders,
    c.total_spent,
    (SELECT COUNT(*) FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')) AS asia_nations,
    p.summary,
    c.order_summary
FROM 
    part_supplier_summary p
JOIN 
    customer_order_summary c ON p.p_name LIKE '%' || c.c_name || '%'
ORDER BY 
    c.total_spent DESC, 
    p.ps_supplycost ASC
LIMIT 100;
