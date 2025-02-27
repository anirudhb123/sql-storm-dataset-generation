WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
), HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    INNER JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        l.l_orderkey
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost_sum
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    n.n_name,
    rp.o_orderkey,
    rp.o_orderdate,
    rp.total_value,
    sp.s_name,
    sp.supply_cost_sum
FROM 
    HighValueLineItems rp
INNER JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = rp.l_orderkey)
INNER JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
INNER JOIN 
    SupplierParts sp ON sp.suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rp.l_orderkey))
WHERE 
    rp.total_value > 1000
ORDER BY 
    n.n_name, rp.total_value DESC;
