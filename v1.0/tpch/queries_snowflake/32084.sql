WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
RankedSales AS (
    SELECT 
        s.o_orderkey,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesCTE s
)
SELECT 
    p.p_name, 
    r.r_name,
    COALESCE(s.avg_supply_cost, 0) AS average_supply_cost,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Sales'
        ELSE 'Other Sales'
    END AS sales_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierCTE s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
FULL OUTER JOIN 
    RankedSales rs ON rs.o_orderkey = ps.ps_partkey
WHERE 
    p.p_size IN (SELECT DISTINCT ps_availqty FROM partsupp WHERE ps_supplycost > 100)
    AND (r.r_name LIKE 'Europe%' OR r.r_name LIKE 'Asia%')
ORDER BY 
    total_sales DESC, 
    average_supply_cost ASC;