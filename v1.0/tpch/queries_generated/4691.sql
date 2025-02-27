WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS order_count,
        DENSE_RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_price,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) OVER (PARTITION BY c.c_custkey) AS avg_order_price
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    COALESCE(ss.s_name, 'Unknown Supplier') AS Supplier_Name,
    COALESCE(cs.c_name, 'Unknown Customer') AS Customer_Name,
    ss.total_sales,
    cs.total_order_price,
    ss.order_count AS supplier_order_count,
    cs.order_count AS customer_order_count,
    CASE 
        WHEN ss.total_sales > cs.total_order_price THEN 'Supplier Dominates'
        WHEN ss.total_sales < cs.total_order_price THEN 'Customer Dominates'
        ELSE 'Equal Footing'
    END AS Dominance_Indicator
FROM 
    SupplierSales ss
FULL OUTER JOIN 
    CustomerOrders cs ON ss.s_suppkey = cs.c_custkey
WHERE 
    (ss.total_sales IS NOT NULL OR cs.total_order_price IS NOT NULL)
    AND (ss.sales_rank <= 5 OR ss.s_suppkey IS NULL) 
ORDER BY 
    ss.total_sales DESC NULLS LAST, cs.total_order_price DESC NULLS LAST;
