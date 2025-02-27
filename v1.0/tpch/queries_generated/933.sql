WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSales AS (
    SELECT 
        p.p_partkey, 
        SUM(l.l_quantity) AS total_quantity_sold,
        COUNT(DISTINCT l.l_orderkey) AS sales_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
),
SupplyOrderDetail AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    cs.c_custkey, 
    cs.total_orders, 
    cs.total_spent, 
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost,
    COALESCE(ps.total_quantity_sold, 0) AS parts_sold,
    COALESCE(sod.total_revenue, 0) AS total_supply_revenue,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS rank
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    SupplierStats ss ON cs.total_orders > 0
LEFT JOIN 
    PartSales ps ON ps.total_quantity_sold > 0
LEFT JOIN 
    SupplyOrderDetail sod ON ps.p_partkey = sod.ps_partkey
WHERE 
    (cs.last_order_date IS NULL OR cs.total_spent > 1000)
ORDER BY 
    cs.total_spent DESC, cs.total_orders DESC;
