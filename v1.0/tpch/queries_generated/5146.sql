WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.revenue,
        n.n_name AS nation_name,
        s.s_name AS supplier_name
    FROM 
        RankedOrders r
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
    JOIN 
        supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey))
    JOIN 
        nation n ON n.n_nationkey = c.c_nationkey
    WHERE 
        r.order_rank <= 5
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.revenue,
    o.nation_name,
    o.supplier_name
FROM 
    TopRevenueOrders o
ORDER BY 
    o.o_orderdate DESC, o.revenue DESC;
