WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER(PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.rn <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_mktsegment,
    sd.s_name,
    sd.s_acctbal,
    SUM(sd.ps_supplycost) AS total_supply_cost
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails sd ON l.l_partkey = sd.ps_partkey
GROUP BY 
    to.o_orderkey, to.o_orderdate, to.o_totalprice, to.c_mktsegment, sd.s_name, sd.s_acctbal
ORDER BY 
    to.o_orderdate DESC, total_supply_cost DESC;
