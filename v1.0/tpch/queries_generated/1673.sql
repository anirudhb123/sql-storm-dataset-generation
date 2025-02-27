WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name, 
    r.r_comment,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    COALESCE(SUM(ro.total_supply_value), 0) AS total_supplier_value,
    COALESCE(AVG(cs.avg_order_value), 0) AS avg_order_value_per_customer
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    CustomerOrderStats co ON cs.c_custkey = co.c_custkey
LEFT JOIN 
    RankedSuppliers ro ON n.n_nationkey = ro.s_nationkey AND ro.supplier_rank <= 3
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_regionkey, r.r_name, r.r_comment
ORDER BY 
    total_customers DESC, total_supplier_value DESC;
