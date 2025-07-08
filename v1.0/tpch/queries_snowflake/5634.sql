
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(ro.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT sd.s_name) AS supplier_count
FROM 
    RankedOrders ro
JOIN 
    lineitem lo ON ro.o_orderkey = lo.l_orderkey
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ro.o_custkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierDetails sd ON lo.l_partkey = sd.ps_partkey AND sd.supp_rank = 1
WHERE 
    ro.price_rank <= 10
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC;
