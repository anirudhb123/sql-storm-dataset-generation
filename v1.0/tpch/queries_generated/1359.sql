WITH SupplierTotalCost AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        COALESCE(max_agg.total_cost, 0) AS max_total_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        (SELECT 
            s_suppkey, 
            MAX(total_cost) AS total_cost 
         FROM 
            SupplierTotalCost 
         GROUP BY 
            s_suppkey) max_agg ON s.s_suppkey = max_agg.s_suppkey
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    s.s_name,
    SUM(ol.revenue) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(co.order_count) AS avg_orders_per_customer,
    p.p_type,
    CASE 
        WHEN MAX(pad.max_total_cost) IS NULL THEN 'No Supplier'
        ELSE 'Supplier Present'
    END AS supplier_status
FROM 
    PartSupplierDetails pad
JOIN 
    OrderLineDetails ol ON pad.p_partkey = ol.l_orderkey
LEFT JOIN 
    CustomerOrderCount co ON co.c_custkey = ol.l_orderkey
LEFT JOIN 
    supplier s ON pad.s_suppkey = s.s_suppkey
JOIN 
    part p ON pad.p_partkey = p.p_partkey
WHERE 
    p.p_size > 10 
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 500)
GROUP BY 
    p.p_name, s.s_name, p.p_type
HAVING 
    SUM(ol.revenue) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 100;
