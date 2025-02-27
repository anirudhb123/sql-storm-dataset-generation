WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SalesInfo AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    s.s_name AS supplier_name,
    s.total_supply_cost,
    c.c_name AS customer_name,
    c.order_count,
    c.avg_order_value,
    CASE 
        WHEN si.net_sales IS NULL THEN 'No Sales'
        ELSE 'Sales: ' || CAST(si.net_sales AS varchar)
    END AS sales_info,
    RANK() OVER (ORDER BY s.total_supply_cost DESC) AS supplier_global_rank
FROM 
    SupplierInfo s
LEFT JOIN 
    CustomerInfo c ON s.supp_supplier = c.c_custkey
JOIN 
    SalesInfo si ON si.l_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_shipmentdate = s.total_supply_cost
    )
WHERE 
    s.supplier_rank <= 5 AND (c.order_count IS NULL OR c.order_count > 0)
ORDER BY 
    s.total_supply_cost DESC, c.avg_order_value DESC;
