WITH SupplierSummary AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
), OrderSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
), CombinedSummary AS (
    SELECT 
        r.r_name,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(s.supplier_count, 0) AS supplier_count,
        COALESCE(o.total_orders, 0) AS total_orders,
        COALESCE(o.total_sales, 0) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        SupplierSummary s ON r.r_regionkey = s.n_nationkey
    LEFT JOIN 
        OrderSummary o ON r.r_regionkey = o.c_nationkey
)
SELECT 
    r_name,
    total_supply_cost,
    supplier_count,
    total_orders,
    total_sales,
    (total_supply_cost / NULLIF(total_sales, 0)) AS supply_cost_to_sales_ratio
FROM 
    CombinedSummary
ORDER BY 
    total_sales DESC, total_supply_cost DESC;
