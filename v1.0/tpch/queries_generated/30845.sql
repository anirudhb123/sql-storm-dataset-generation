WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
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
        s.rank <= 10
),
SupplierRegions AS (
    SELECT 
        s.s_suppkey,
        n.n_name as nation,
        r.r_name as region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalReport AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ss.total_cost, 0) AS total_cost,
        COALESCE(ts.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(ts.total_sales, 0) > 0 THEN 'Active Customer'
            ELSE 'Inactive Customer'
        END AS customer_status
    FROM 
        part p
    LEFT JOIN 
        PartSupplierSales ss ON p.p_partkey = ss.ps_partkey
    LEFT JOIN 
        TopSales ts ON ts.c_custkey = (SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_name LIKE '%' || p.p_name || '%')
    WHERE 
        p.p_retailprice > 100.00
)
SELECT 
    COUNT(*) AS total_parts,
    AVG(total_cost) AS avg_supply_cost,
    SUM(total_sales) AS total_revenue,
    MAX(total_sales) AS max_single_sales,
    STRING_AGG(DISTINCT customer_status, '; ') AS customer_status_summary
FROM 
    FinalReport
WHERE 
    total_cost IS NOT NULL
GROUP BY 
    total_cost > 500
HAVING 
    SUM(total_sales) > 10000
ORDER BY 
    total_parts DESC;
