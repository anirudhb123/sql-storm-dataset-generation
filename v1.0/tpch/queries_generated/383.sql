WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
), 
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    ss.total_available,
    ss.total_supplycost,
    cs.order_count,
    cs.avg_order_value
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierSummary ss ON ss.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN 
    CustomerStats cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
WHERE 
    r.rn = 1
ORDER BY 
    r.o_totalprice DESC NULLS LAST;
