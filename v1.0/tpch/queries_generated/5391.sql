WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),
SupplierPartCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LowCostParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        sp.total_cost
    FROM 
        part p
    JOIN 
        SupplierPartCost sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        sp.total_cost < 1000
)
SELECT 
    to.o_orderkey,
    to.o_totalprice,
    to.c_mktsegment,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    p.p_name,
    p.p_size
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    LowCostParts p ON l.l_partkey = p.p_partkey
ORDER BY 
    to.o_orderkey, p.p_size DESC;
