WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, l.l_partkey
)
SELECT 
    r.r_name AS region,
    s.s_name AS supplier,
    c.c_name AS customer,
    SUM(ols.net_revenue) AS total_net_revenue,
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    cs.total_orders,
    cs.total_spent
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    OrderLineItems ols ON ols.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    CustomerOrders cs ON c.c_custkey = cs.c_custkey
GROUP BY 
    r.r_name, s.s_name, c.c_name
ORDER BY 
    total_net_revenue DESC, total_supplier_cost DESC
LIMIT 10;
