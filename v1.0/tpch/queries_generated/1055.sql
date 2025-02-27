WITH RankedLineItems AS (
    SELECT 
        l_orderkey,
        l_partkey,
        l_suppkey,
        l_linenumber,
        l_quantity,
        l_extendedprice,
        l_discount,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rn,
        l_shipdate
    FROM 
        lineitem
    WHERE 
        l_returnflag = 'N' AND l_linestatus = 'O'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    s.s_name,
    s.nation_name,
    s.region_name,
    s.s_acctbal,
    COALESCE(SUM(t.total_sales), 0) AS total_sales,
    COUNT(DISTINCT r.l_orderkey) AS order_count,
    REPLACE(s.s_name, 'Supplier', 'Distributor') AS distributor_name
FROM 
    SupplierInfo s
LEFT JOIN 
    TotalSales t ON s.s_suppkey = t.o_orderkey
LEFT JOIN 
    RankedLineItems r ON s.s_suppkey = r.l_suppkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND 
    (s.s_name LIKE '%Corp%' OR s.s_comment IS NULL)
GROUP BY 
    s.s_name, s.nation_name, s.region_name, s.s_acctbal
ORDER BY 
    total_sales DESC, order_count ASC
LIMIT 10;
