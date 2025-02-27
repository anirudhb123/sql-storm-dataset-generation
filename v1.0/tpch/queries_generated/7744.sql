WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS rank
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
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2023-12-31'
),
TopOrders AS (
    SELECT 
        * 
    FROM 
        RankedOrders 
    WHERE 
        rank = 1
)
SELECT 
    TOP 10 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    t.c_name AS customer_name,
    t.supplier_name,
    t.p_name AS part_name
FROM 
    TopOrders t
ORDER BY 
    t.o_totalprice DESC;
