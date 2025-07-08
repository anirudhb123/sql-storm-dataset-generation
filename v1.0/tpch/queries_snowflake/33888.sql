WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
), 
TopSales AS (
    SELECT 
        s.o_orderkey,
        s.total_sales,
        c.c_mktsegment
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.o_orderkey = c.c_custkey
    WHERE 
        s.rn <= 5
), 
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey
), 
MaxAvailability AS (
    SELECT 
        MAX(total_available) AS max_avail
    FROM 
        SupplierPart
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High'
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    r.r_name
FROM 
    part p
LEFT JOIN 
    TopSales s ON p.p_partkey = s.o_orderkey
JOIN 
    supplier su ON su.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey 
        ORDER BY 
            ps.ps_supplycost
        LIMIT 1
    )
JOIN 
    nation n ON su.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND (r.r_name LIKE 'N%' OR r.r_name IS NULL)
ORDER BY 
    p.p_retailprice DESC 
LIMIT 10;
