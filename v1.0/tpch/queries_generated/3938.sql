WITH RankedSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    INNER JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        l.l_partkey
), 
SupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        COALESCE(NULLIF(ps.ps_supplycost * ps.ps_availqty, 0), NULL) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(rs.net_sales) AS total_sales,
    AVG(sd.total_supply_value) AS average_supply_value,
    COUNT(sd.p_partkey) AS distinct_parts,
    MAX(sd.ps_supplycost) AS max_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedSales rs ON rs.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN 
    SupplierDetails sd ON sd.p_partkey = rs.l_partkey
WHERE 
    sd.total_supply_value IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    total_sales > 10000
ORDER BY 
    total_sales DESC;
