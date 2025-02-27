WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT 
        ps.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM 
        SupplierHierarchy sh
    JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
MinMaxOrders AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_totalprice) AS max_order_value,
        MIN(o.o_totalprice) AS min_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        AVG(o.o_totalprice) > 500
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    SUM(ol.total_price_after_discount) AS total_sales,
    COUNT(DISTINCT ol.l_orderkey) AS total_orders,
    MAX(mo.max_order_value) AS highest_order_value,
    MIN(mo.min_order_value) AS lowest_order_value,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers_in_hierarchy
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    OrderLineSummary ol ON ol.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = s.s_suppkey)
LEFT JOIN 
    MinMaxOrders mo ON mo.c_custkey = s.s_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(ol.total_price_after_discount) > 1000000
ORDER BY 
    total_sales DESC;
