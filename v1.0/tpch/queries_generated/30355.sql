WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01'
    GROUP BY 
        o.o_orderkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CountrySales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(SALES.total_sales) AS nation_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        SalesCTE SALES ON c.c_custkey = SALES.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
FinalReport AS (
    SELECT 
        r.r_name AS Region,
        cs.n_name AS Nation,
        cs.nation_sales,
        COALESCE(rs.total_available, 0) AS total_available,
        CASE 
            WHEN cs.nation_sales > 10000 THEN 'High Sales'
            WHEN cs.nation_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        CountrySales cs ON n.n_nationkey = cs.n_nationkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_supply_rank <= 5
)
SELECT 
    Region,
    Nation,
    SUM(nation_sales) AS Total_Nation_Sales,
    AVG(total_available) AS Average_Available_Supplies,
    MAX(nation_sales) AS Max_Sales,
    MIN(nation_sales) AS Min_Sales,
    STRING_AGG(sales_category, ', ') AS Sales_Categories
FROM 
    FinalReport
GROUP BY 
    Region, Nation
ORDER BY 
    Total_Nation_Sales DESC;
