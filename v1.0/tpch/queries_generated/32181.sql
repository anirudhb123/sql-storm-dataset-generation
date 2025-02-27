WITH RECURSIVE RegionSupplier AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        r.r_name = 'ASIA'
    UNION ALL
    SELECT 
        rs.r_regionkey,
        rs.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RegionSupplier rs
    JOIN 
        nation n ON rs.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal > 1000
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty
    FROM 
        partsupp ps
    JOIN 
        Supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    SUM(as.total_sales) AS total_sales,
    AVG(ps.ps_availqty) AS average_avail_qty,
    COUNT(DISTINCT rs.s_suppkey) AS total_suppliers
FROM 
    part p
LEFT JOIN 
    PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    AggregatedSales as ON p.p_partkey = as.l_partkey
LEFT JOIN 
    RegionSupplier rs ON ps.ps_suppkey = rs.s_suppkey
WHERE 
    p.p_retailprice > 100.00
    AND (p.p_container IS NULL OR p.p_container LIKE '%BOX%')
GROUP BY 
    p.p_partkey, p.p_name, supplier_name
HAVING 
    total_sales > 5000
ORDER BY 
    total_sales DESC, average_avail_qty DESC;
