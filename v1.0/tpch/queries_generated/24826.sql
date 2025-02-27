WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_returnflag = 'N'
        AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        s.s_suppkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        n.n_name IS NOT NULL
)
SELECT 
    nr.n_name AS nation_name,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_count,
    SUM(COALESCE(ss.total_sales, 0)) AS total_sales_amount,
    SUM(CASE WHEN rp.rn <= 3 THEN rp.p_retailprice ELSE 0 END) AS top_part_retail_prices,
    STRING_AGG(rp.p_name ORDER BY rp.p_retailprice DESC) AS top_part_names
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierSales ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = nr.n_name)
JOIN 
    NationRegion nr ON c.c_nationkey = nr.n_nationkey
WHERE 
    rp.p_retailprice > (SELECT AVG(p.p_retailprice) FROM part p)
GROUP BY 
    nr.n_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
