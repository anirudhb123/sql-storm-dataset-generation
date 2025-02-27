WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        r.r_name AS region_name,
        SUM(CASE WHEN oi.total_order_value IS NOT NULL THEN oi.total_order_value ELSE 0 END) AS total_sales
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        OrderInfo oi ON c.c_custkey = oi.o_custkey
    GROUP BY 
        c.c_custkey, r.r_name
)
SELECT 
    cr.region_name,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    SUM(cr.total_sales) AS total_sales_amount,
    AVG(supplier_costs.total_supply_cost) AS average_supplier_cost
FROM 
    CustomerRegions cr
JOIN 
    SupplierCosts supplier_costs ON cr.region_name = (
        SELECT r.r_name 
        FROM nation n 
        JOIN region r ON n.n_regionkey = r.r_regionkey 
        WHERE cr.c_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_nationkey = n.n_nationkey
        ) 
        LIMIT 1
    )
GROUP BY 
    cr.region_name
ORDER BY 
    total_sales_amount DESC;