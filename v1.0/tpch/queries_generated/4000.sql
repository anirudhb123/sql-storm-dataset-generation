WITH SupplierStats AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_acctbal
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(*) AS total_line_items,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Other' 
        END AS order_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.revenue,
        od.total_line_items,
        od.o_orderdate,
        od.order_status,
        ROW_NUMBER() OVER (PARTITION BY od.order_status ORDER BY od.revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
    WHERE 
        od.revenue > (SELECT AVG(revenue) FROM OrderDetails) 
)

SELECT 
    s.s_name,
    s.total_available_quantity,
    s.average_supply_cost,
    hvo.o_orderkey,
    hvo.revenue,
    hvo.total_line_items,
    hvo.o_orderdate,
    hvo.order_status
FROM 
    HighValueOrders hvo
LEFT JOIN 
    SupplierStats s ON hvo.revenue > s.average_supply_cost
WHERE 
    hvo.revenue IS NOT NULL 
    AND s.total_available_quantity IS NOT NULL
ORDER BY 
    s.s_name, hvo.revenue DESC;
