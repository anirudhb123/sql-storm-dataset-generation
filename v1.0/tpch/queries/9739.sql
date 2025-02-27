WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ro.c_acctbal,
    ps.total_available_qty,
    ps.avg_supply_cost,
    ts.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    PartSupplierSummary ps ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
