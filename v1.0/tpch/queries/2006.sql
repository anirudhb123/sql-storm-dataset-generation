WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderInfo AS (
    SELECT 
        c.c_nationkey,
        o.o_orderkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_nationkey, o.o_orderkey
),
SupplierSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)

SELECT 
    r.r_name,
    COALESCE(SUM(order_count), 0) AS total_orders,
    COALESCE(SUM(total_order_value), 0) AS total_revenue,
    COALESCE(SUM(supplier_count), 0) AS total_suppliers,
    COALESCE(SUM(total_supply_cost), 0) AS total_supply_cost,
    AVG(total_sales) AS avg_sales_per_part
FROM 
    region r
LEFT JOIN 
    OrderInfo oi ON r.r_regionkey = oi.c_nationkey
LEFT JOIN 
    SupplierSummary ss ON r.r_name = ss.n_name
LEFT JOIN 
    RankedSales rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.p_partkey)
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
