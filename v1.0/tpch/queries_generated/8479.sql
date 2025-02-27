WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS sales_month, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        sales_month
),
SalesByRegion AS (
    SELECT 
        r.r_name, 
        SUM(ms.total_sales) AS total_region_sales
    FROM 
        MonthlySales ms
    JOIN 
        orders o ON ms.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT h.c_custkey) AS high_value_customers,
    SUM(s.total_region_sales) AS total_sales_in_region,
    AVG(s.total_region_sales) AS average_sales_per_month
FROM 
    SalesByRegion s
JOIN 
    HighValueCustomers h ON s.region = h.c_name
JOIN 
    RankedSuppliers rs ON rs.supplier_rank = 1
GROUP BY 
    r.r_name
ORDER BY 
    total_sales_in_region DESC;
