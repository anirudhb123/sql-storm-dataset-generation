WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
HighValueOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM
        RankedOrders ro
    WHERE
        ro.order_rank <= 5
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.total_supply_cost
    FROM 
        part p
    JOIN 
        PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 1000
    ORDER BY 
        ps.total_supply_cost DESC
    LIMIT 10
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.c_name,
    tp.p_name,
    tp.total_supply_cost
FROM 
    HighValueOrders h
JOIN 
    TopParts tp ON h.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = tp.p_partkey)
ORDER BY 
    h.o_totalprice DESC, h.o_orderdate ASC;