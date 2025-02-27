WITH RECURSIVE TotalSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
    UNION ALL
    SELECT 
        c.c_custkey,
        MAX(ts.total_sales) + SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        TotalSales ts
    JOIN 
        customer c ON c.c_custkey = ts.c_custkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' -- Finalized orders only
    GROUP BY 
        c.c_custkey
),
PartSupplierStats AS (
    SELECT
        p.p_partkey,
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COALESCE(NULLIF(SUM(l.l_quantity), 0), 1) AS total_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, s.s_nationkey
),
RankedSales AS (
    SELECT 
        c.c_custkey,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
    JOIN 
        customer c ON ts.c_custkey = c.c_custkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.avg_supply_cost,
        CASE WHEN ps.total_quantity IS NULL THEN 'No Sales' ELSE 'Sold' END AS sales_status
    FROM 
        part p
    LEFT JOIN 
        PartSupplierStats ps ON p.p_partkey = ps.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
        AND ps.avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT fp.p_partkey) AS sold_parts_count,
    SUM(fp.p_retailprice) AS total_retail_value,
    ARRAY_AGG(DISTINCT c.c_name) AS customers
FROM 
    FilteredParts fp
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = fp.p_partkey LIMIT 1)
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_custkey IN (SELECT c_custkey FROM RankedSales WHERE sales_rank <= 10)
GROUP BY 
    r.r_name
HAVING 
    SUM(fp.p_retailprice) > 10000
ORDER BY 
    total_retail_value DESC;
