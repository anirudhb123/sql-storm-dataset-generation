WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    tr.region_name,
    tr.total_sales,
    p.p_brand,
    p.p_name,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_availqty) AS min_available_qty
FROM 
    TopRegions tr
JOIN 
    partsupp ps ON tr.region_name = (
        SELECT 
            r.r_name 
        FROM 
            region r
        JOIN 
            nation n ON r.r_regionkey = n.n_regionkey
        JOIN 
            supplier s ON n.n_nationkey = s.s_nationkey
        WHERE 
            s.s_suppkey = ps.ps_suppkey
    )
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    tr.sales_rank <= 5
GROUP BY 
    tr.region_name, tr.total_sales, p.p_brand, p.p_name
ORDER BY 
    tr.total_sales DESC, p.p_brand;
