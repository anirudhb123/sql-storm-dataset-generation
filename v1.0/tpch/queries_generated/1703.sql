WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name, n.n_name
), RankedSales AS (
    SELECT 
        region_name,
        nation_name,
        total_sales,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), HighPerformingNations AS (
    SELECT 
        region_name,
        nation_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 3
), SupplierPerformance AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    hp.region_name,
    hp.nation_name,
    hp.total_sales,
    sp.supplier_name,
    sp.total_available,
    sp.avg_supply_cost
FROM 
    HighPerformingNations hp
LEFT JOIN 
    SupplierPerformance sp ON hp.nation_name = (
        SELECT 
            n.n_name 
        FROM 
            nation n 
        WHERE 
            n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_name = sp.supplier_name)
    )
ORDER BY 
    hp.region_name, hp.nation_name, hp.total_sales DESC;
