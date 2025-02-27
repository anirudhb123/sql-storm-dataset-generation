WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        s.total_sales
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_custkey = c.c_custkey
    WHERE 
        s.sales_rank <= 10
),
SuppliersWithHighSupplyCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
RegionCount AS (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        nation n
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ts.c_custkey) AS num_high_sales_customers,
    SUM(sh.total_supply_cost) AS total_high_supply_cost,
    rc.nation_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSales ts ON ts.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    SuppliersWithHighSupplyCost sh ON sh.ps_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
JOIN 
    RegionCount rc ON rc.n_regionkey = n.n_regionkey
GROUP BY 
    r.r_name, rc.nation_count
HAVING 
    SUM(sh.total_supply_cost) IS NOT NULL
ORDER BY 
    r.r_name ASC;
