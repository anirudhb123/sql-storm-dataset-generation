WITH SupplierSales AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(ss.total_sales) AS total_nation_sales
    FROM 
        nation n
    LEFT JOIN 
        SupplierSales ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_customer_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name
)
SELECT 
    ns.n_name,
    COALESCE(ns.total_nation_sales, 0) AS nation_sales,
    COALESCE(cs.total_customer_spent, 0) AS customer_spent,
    ns.total_nation_sales - COALESCE(cs.total_customer_spent, 0) AS sales_difference
FROM 
    NationSales ns
FULL OUTER JOIN 
    CustomerOrders cs ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = cs.total_customer_spent)
WHERE 
    ns.total_nation_sales IS NOT NULL OR cs.total_customer_spent IS NOT NULL
ORDER BY 
    sales_difference DESC
LIMIT 10;
