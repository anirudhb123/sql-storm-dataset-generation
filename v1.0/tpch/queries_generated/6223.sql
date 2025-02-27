WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    p.p_partkey,
    p.total_available_qty,
    p.total_supply_cost
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    PartSupplierSummary p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= to.o_orderdate
ORDER BY 
    to.o_orderdate DESC, to.o_totalprice DESC, p.total_available_qty DESC;
