
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal > 5000
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
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 20000
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ts.s_name AS top_supplier,
    oli.total_revenue,
    oli.item_count
FROM 
    RankedOrders r
LEFT JOIN 
    OrderLineItems oli ON r.o_orderkey = oli.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON oli.l_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.order_rank <= 5
ORDER BY 
    r.o_totalprice DESC, r.o_orderdate DESC;
