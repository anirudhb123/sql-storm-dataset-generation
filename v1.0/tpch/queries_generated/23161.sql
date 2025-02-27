WITH SupplierInfo AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_acctbal
    FROM 
        supplier
    WHERE 
        s_acctbal IS NOT NULL
    GROUP BY 
        s_nationkey
    HAVING 
        COUNT(DISTINCT s_suppkey) > 5
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 0
), 
AnnualSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_lineitem_sales
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
), 
TopRegions AS (
    SELECT 
        r.r_regionkey,
        SUM(si.total_acctbal) AS region_total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS active_customers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierInfo si ON n.n_nationkey = si.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey
    HAVING 
        SUM(si.total_acctbal) > 10000
)

SELECT 
    r.r_regionkey,
    r.r_name,
    COALESCE(c.total_orders, 0) AS active_orders,
    COALESCE(c.total_spent, 0) AS customer_spending,
    SUM(l.total_lineitem_sales) AS total_sales,
    CASE 
        WHEN SUM(si.total_acctbal) IS NULL THEN 'No Data'
        ELSE 'Data Available'
    END AS supply_status,
    ROW_NUMBER() OVER (ORDER BY region_total_acctbal DESC) AS region_rank
FROM 
    TopRegions r
LEFT JOIN 
    CustomerOrders c ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (SELECT DISTINCT c_nationkey FROM customer))
LEFT JOIN 
    AnnualSales l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)))
GROUP BY 
    r.r_regionkey, r.r_name, c.total_orders, c.total_spent
ORDER BY 
    region_rank
OFFSET 3 ROWS FETCH NEXT 5 ROWS ONLY;
