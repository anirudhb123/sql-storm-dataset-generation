WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_ret = 'Y'
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        SUM(sd.total_sales) AS nation_total_sales
    FROM 
        nation n
    LEFT JOIN 
        SalesData sd ON n.n_nationkey = sd.c_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    ps.p_partkey,
    rp.p_name,
    ns.nation_total_sales,
    COALESCE(ns.nation_total_sales, 0) AS adjusted_sales,
    (rp.p_retailprice * (CASE 
        WHEN ns.nation_total_sales IS NULL THEN 0 
        ELSE 1 
    END)) AS calculated_retail_value,
    (SELECT AVG(l.l_quantity)
     FROM lineitem l
     WHERE l.l_partkey = rp.p_partkey AND l.l_shipdate >= '2023-01-01') AS avg_quantity_sold
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    NationSales ns ON ps.ps_suppkey = ns.n_nationkey
WHERE 
    rp.price_rank <= 5
ORDER BY 
    calculated_retail_value DESC;
