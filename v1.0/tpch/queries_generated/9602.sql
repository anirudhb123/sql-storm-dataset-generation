WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority, c.c_name
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderstatus,
        r.o_totalprice,
        r.o_orderdate,
        r.o_orderpriority,
        r.c_name,
        COUNT(*) OVER(PARTITION BY r.o_orderstatus) AS status_count
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderstatus,
    t.o_totalprice,
    t.o_orderdate,
    t.o_orderpriority,
    t.c_name,
    t.status_count,
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
FROM 
    TopOrders t
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = t.o_orderkey)
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
GROUP BY 
    t.o_orderkey, t.o_orderstatus, t.o_totalprice, t.o_orderdate, t.o_orderpriority, t.c_name, t.status_count, p.p_name
ORDER BY 
    total_revenue DESC, t.o_orderdate ASC;
