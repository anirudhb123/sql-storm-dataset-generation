WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01' 
        AND o.o_orderdate < '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    o.o_orderkey,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    cr.region_name,
    ro.order_rank,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(cd.c_acctbal) AS avg_acctbal
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierDetails s ON l.l_suppkey = s.s_suppkey
JOIN 
    CustomerRegion cr ON ro.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_custkey = cr.c_custkey)
GROUP BY 
    o.o_orderkey, s.s_name, cr.region_name, ro.order_rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 
ORDER BY 
    revenue DESC
LIMIT 10;
