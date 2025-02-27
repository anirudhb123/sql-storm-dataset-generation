WITH RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01'
        AND o.o_orderdate < DATE '2021-12-31'
    GROUP BY 
        r.r_name
),
SupplierRanked AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
SalesWithSuppliers AS (
    SELECT 
        rs.r_name,
        rs.total_sales,
        sr.s_name,
        sr.total_supply_cost
    FROM 
        RegionSales rs
    LEFT JOIN 
        SupplierRanked sr ON rs.r_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = sr.s_name)))
)
SELECT 
    r_name,
    total_sales,
    s_name,
    total_supply_cost,
    CASE 
        WHEN total_supply_cost IS NULL THEN 'No Supplies'
        ELSE 'Supplied'
    END AS supply_status
FROM  
    SalesWithSuppliers
WHERE 
    total_sales > 500000
ORDER BY 
    total_sales DESC
LIMIT 10;
