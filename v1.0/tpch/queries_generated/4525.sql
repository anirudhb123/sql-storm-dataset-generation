WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
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
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_sales,
        COUNT(l.l_linenumber) AS line_item_count
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ss.s_name AS supplier_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    lis.total_line_item_sales,
    lis.line_item_count
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    SupplierStats ss ON cs.total_orders > 0
LEFT JOIN 
    LineItemStats lis ON cs.total_orders > 0
WHERE
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC, ss.avg_supply_cost ASC
LIMIT 10;
