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
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.item_count,
        CASE 
            WHEN os.total_revenue > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS order_type
    FROM 
        OrderSummary os
    WHERE 
        os.revenue_rank <= 100
)
SELECT 
    n.n_name AS supplier_nation,
    ss.s_name AS supplier_name,
    COALESCE(hvo.item_count, 0) AS high_value_order_count,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    SUM(hvo.total_revenue) AS total_high_value_revenue
FROM 
    SupplierStats ss
LEFT JOIN 
    nation n ON ss.s_suppkey = n.n_nationkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.total_revenue > 10000
GROUP BY 
    n.n_name, ss.s_name, ss.total_avail_qty, ss.avg_supply_cost
HAVING 
    AVG(ss.avg_supply_cost) IS NOT NULL
ORDER BY 
    total_high_value_revenue DESC, supplier_nation, supplier_name;
