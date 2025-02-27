WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_item_no
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    o.cust_summary.c_name AS customer_name,
    p.supplier_name,
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS net_revenue,
    COUNT(DISTINCT ol.o_orderkey) AS order_count,
    p.total_available_quantity,
    CASE 
        WHEN MAX(co.last_order_date) IS NULL THEN 'No Orders'
        ELSE TO_CHAR(MAX(co.last_order_date), 'YYYY-MM-DD')
    END AS last_order_date,
    COALESCE(SUM(p.avg_supply_cost), 0) AS avg_supply_cost,
    COUNT(DISTINCT CASE WHEN ol.l_returnflag = 'R' THEN ol.l_partkey END) AS returns_count
FROM 
    CustomerOrderSummary co
JOIN 
    OrderLineItems ol ON co.c_custkey = ol.o_orderkey
JOIN 
    PartSupplierDetails p ON ol.l_partkey = p.ps_partkey
LEFT JOIN 
    nation n ON co.c_custkey = n.n_nationkey
WHERE 
    (p.avg_supply_cost < 50 OR p.supplier_name LIKE '%Top%')
    AND (ol.l_quantity IS NOT NULL OR ol.l_discount IS NULL)
GROUP BY 
    o.cust_summary.c_name, p.supplier_name, p.total_available_quantity
ORDER BY 
    net_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
