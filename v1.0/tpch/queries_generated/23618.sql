WITH CTE_Supplier_Stats AS (
    SELECT 
        s_nationkey,
        COUNT(s_suppkey) AS supplier_count,
        AVG(s_acctbal) AS avg_acctbal,
        SUM(CASE WHEN s_comment LIKE '%reliable%' THEN 1 ELSE 0 END) AS reliable_suppliers
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
CTE_Orders_Aggregate AS (
    SELECT 
        o_custkey,
        SUM(o_totalprice) AS total_spent,
        COUNT(o_orderkey) AS order_count,
        MAX(o_orderdate) AS last_order_date
    FROM 
        orders
    WHERE 
        o_orderdate >= '2022-01-01'
    GROUP BY 
        o_custkey
),
CTE_LineItem_Summary AS (
    SELECT 
        l_orderkey,
        SUM(l_quantity * (1 - l_discount)) AS total_quantity_discounted,
        AVG(l_extendedprice) FILTER (WHERE l_returnflag = 'R') AS avg_returned_price
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(ss.supplier_count, 0) AS total_suppliers,
    COALESCE(oa.total_spent, 0) AS total_spent,
    COALESCE(ls.total_quantity_discounted, 0) AS total_discounted_quantity,
    ROUND((COALESCE(ss.avg_acctbal, 0) - COALESCE(oa.order_count, 0)) * 100.0, 2) AS adjusted_account_balance,
    CASE 
        WHEN COALESCE(oa.last_order_date, '1900-01-01') < DATEADD(month, -6, CURRENT_DATE) THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CTE_Supplier_Stats ss ON ss.s_nationkey = n.n_nationkey
LEFT JOIN 
    CTE_Orders_Aggregate oa ON oa.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN 
    CTE_LineItem_Summary ls ON ls.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = oa.o_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    r.r_name NOT LIKE '%Unknown%'
ORDER BY 
    nation_name, region_name
LIMIT 100 OFFSET 10;
