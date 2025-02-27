WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(ss.total_supply_value), 0) AS total_supply_value,
    COALESCE(SUM(co.total_spent), 0) AS total_customer_spent,
    COUNT(DISTINCT ss.s_suppkey) AS distinct_suppliers,
    COUNT(DISTINCT co.c_custkey) AS distinct_customers,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts,
    COALESCE(AVG(co.order_count), 0) AS avg_orders_per_customer
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey  -- Joining based on customer data
LEFT JOIN 
    part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    total_supply_value DESC, total_customer_spent DESC;
