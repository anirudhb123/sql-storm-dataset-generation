WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY s_acctbal DESC) AS rnk,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE
            WHEN p.p_size IS NULL THEN 0
            ELSE p.p_size
        END AS size_adjusted
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN (SELECT AVG(ps_supplycost) FROM partsupp) AND (SELECT MAX(ps_supplycost) FROM partsupp)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_retailprice,
    od.total_price,
    ss.s_suppkey,
    ss.s_name
FROM 
    FilteredParts fp
LEFT JOIN 
    RankedSuppliers ss ON ss.rnk <= 3
INNER JOIN 
    OrderDetails od ON od.total_price IS NOT NULL 
WHERE 
    (fp.size_adjusted IS NOT NULL OR fp.p_retailprice > 100)
    AND ss.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name NOT LIKE '%land%')
ORDER BY 
    fp.p_retailprice DESC, 
    od.last_ship_date ASC 
FETCH FIRST 10 ROWS ONLY;
