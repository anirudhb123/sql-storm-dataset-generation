WITH RECURSIVE MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS order_year,
        EXTRACT(MONTH FROM o_orderdate) AS order_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        order_year, order_month
    UNION ALL
    SELECT 
        order_year,
        order_month + 1,
        SUM(l_extendedprice * (1 - l_discount))
    FROM 
        MonthlySales ms
    JOIN 
        orders o ON EXTRACT(YEAR FROM o_orderdate) = ms.order_year AND 
                    EXTRACT(MONTH FROM o_orderdate) = ms.order_month + 1
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        ms.order_month < 12
    GROUP BY 
        order_year, order_month
),
PartSupplier AS (
    SELECT 
        p.p_name, 
        ps.ps_partkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    GROUP BY 
        s.s_name 
    HAVING 
        total_cost > 10000
),
FinalResults AS (
    SELECT 
        ms.order_year,
        ms.order_month,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        SUM(ms.total_sales) AS monthly_sales,
        COALESCE(AVG(hvs.total_cost), 0) AS avg_high_value_cost
    FROM 
        MonthlySales ms
    LEFT JOIN 
        orders o ON ms.order_year = EXTRACT(YEAR FROM o.o_orderdate) AND 
                    ms.order_month = EXTRACT(MONTH FROM o.o_orderdate)
    LEFT JOIN 
        HighValueSuppliers hvs ON TRUE
    GROUP BY 
        ms.order_year, ms.order_month
)
SELECT 
    fr.order_year,
    fr.order_month,
    fr.unique_customers,
    fr.monthly_sales,
    fr.avg_high_value_cost,
    CASE 
        WHEN fr.monthly_sales > 50000 THEN 'High Volume'
        WHEN fr.monthly_sales BETWEEN 20000 AND 50000 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END AS sales_category
FROM 
    FinalResults fr
ORDER BY 
    fr.order_year, fr.order_month;
