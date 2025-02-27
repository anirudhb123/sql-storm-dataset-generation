WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        RankedOrders r
    LEFT JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.order_rank <= 100
    GROUP BY 
        r.o_orderkey,
        r.o_totalprice
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        s.s_acctbal > 0
),
TopSuppliers AS (
    SELECT 
        sd.ps_partkey,
        sd.supp_name,
        sd.s_acctbal
    FROM 
        SupplierDetails sd
    WHERE 
        sd.supplier_rank <= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ts.supp_name, 'No Supplier') AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    TopSuppliers ts ON l.l_partkey = ts.ps_partkey
JOIN 
    supplier s ON ts.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_returnflag = 'R' OR l.l_returnflag IS NULL
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    ts.supp_name,
    r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 AND 
    COUNT(DISTINCT l.l_orderkey) > 2
ORDER BY 
    revenue DESC NULLS LAST;
