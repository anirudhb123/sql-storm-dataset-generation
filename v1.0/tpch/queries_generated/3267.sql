WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_orders_value,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS item_count,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cp.c_name AS customer_name,
    sp.s_name AS supplier_name,
    l.revenue AS order_revenue,
    l.item_count,
    sp.total_supply_value AS supplier_value,
    cp.total_orders_value AS customer_order_value,
    ROW_NUMBER() OVER (PARTITION BY cp.c_custkey ORDER BY l.revenue DESC) AS order_rank
FROM 
    CustomerOrderStats cp
JOIN 
    LineItemStats l ON cp.last_order_date = (SELECT MAX(o.o_orderdate) FROM orders o WHERE o.o_custkey = cp.c_custkey)
LEFT JOIN 
    SupplierPerformance sp ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cp.c_custkey)
WHERE 
    cp.order_count > 0 AND
    (sp.total_supply_value IS NOT NULL OR cp.total_orders_value > 1000)
ORDER BY 
    cp.total_orders_value DESC, sp.total_supply_value DESC;
