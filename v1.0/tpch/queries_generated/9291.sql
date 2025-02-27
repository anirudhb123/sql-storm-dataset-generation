WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
)
SELECT 
    o_orderkey,
    o_orderdate,
    c_name,
    total_revenue = SUM(o_totalprice) OVER (),
    suppliers = STRING_AGG(supplier_name, ', ') WITHIN GROUP (ORDER BY supplier_name) FILTER (WHERE order_rank = 1)
FROM 
    RankedOrders
GROUP BY 
    o_orderkey, o_orderdate, c_name
HAVING 
    SUM(o_totalprice) > 1000
ORDER BY 
    o_orderdate DESC, total_revenue DESC
LIMIT 10;
