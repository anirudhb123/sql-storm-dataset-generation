WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_supplycost) AS unique_costs,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MIN(ps.ps_supplycost) AS min_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spending,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_line_items,
        SUM(l.l_tax) AS total_tax
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ss.s_name,
    ss.unique_costs,
    ss.total_avail_qty,
    os.total_orders,
    os.total_spending,
    os.avg_order_value,
    os.last_order_date,
    lis.total_revenue,
    lis.total_line_items,
    lis.total_tax
FROM 
    SupplierStats ss
LEFT OUTER JOIN 
    OrderStats os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
LEFT JOIN 
    LineItemStats lis ON lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = os.o_custkey)
WHERE 
    ss.total_avail_qty > 1000
ORDER BY 
    ss.total_avail_qty DESC,
    os.total_spending DESC
LIMIT 50;
