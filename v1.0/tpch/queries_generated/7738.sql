WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    SUM(cs.total_spent) AS total_spent_by_customers,
    AVG(cs.total_orders) AS avg_orders_per_customer,
    SUM(ss.total_avail_qty) AS total_available_qty_from_suppliers,
    SUM(ps.total_quantity_sold) AS total_quantity_sold_for_parts
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey 
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey 
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey 
JOIN 
    CustomerStats cs ON c.c_custkey = cs.c_custkey 
JOIN 
    PartStats ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey)
GROUP BY 
    r.r_name
ORDER BY 
    total_spent_by_customers DESC, region_name;
