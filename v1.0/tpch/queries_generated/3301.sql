WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
),
PartSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    INNER JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-06-01' AND DATE '2023-12-31'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_sales,
    COALESCE(sd.total_parts, 0) AS total_supplier_parts,
    RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
FROM 
    part p
LEFT JOIN 
    PartSales ps ON p.p_partkey = ps.l_partkey
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey IN (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_acctbal > 1000)
    )
WHERE 
    (p.p_size BETWEEN 10 AND 20 OR p.p_type LIKE '%steel%')
ORDER BY 
    sales_rank
LIMIT 50;
