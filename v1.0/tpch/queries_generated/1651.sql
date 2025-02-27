WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
JoinedData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        pd.total_sales,
        sd.s_name AS supplier_name,
        sd.nation_name
    FROM 
        RankedOrders o
    LEFT JOIN 
        PartSales pd ON pd.total_sales IS NOT NULL
    LEFT JOIN 
        partsupp ps ON ps.ps_partkey = pd.p_partkey
    LEFT JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    j.o_orderkey,
    j.o_orderdate,
    COALESCE(j.total_sales, 0) AS total_sales,
    j.supplier_name,
    j.nation_name
FROM 
    JoinedData j
WHERE 
    j.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND (j.supplier_name IS NOT NULL OR j.nation_name IS NOT NULL)
ORDER BY 
    j.o_orderdate DESC, j.total_sales DESC
LIMIT 100;
