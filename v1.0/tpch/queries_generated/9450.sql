WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
Top100Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        c.c_name,
        n.n_name AS nation_name,
        p.p_name AS part_name,
        SUM(li.l_quantity) AS total_quantity
    FROM 
        RankedOrders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        part p ON li.l_partkey = p.p_partkey
    WHERE 
        o.rn <= 100
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus, o.o_orderdate, c.c_name, n.n_name, p.p_name
)
SELECT 
    nation_name,
    COUNT(DISTINCT o_orderkey) AS order_count,
    SUM(total_quantity) AS total_quantity_sold,
    AVG(o_totalprice) AS avg_order_value
FROM 
    Top100Orders
GROUP BY 
    nation_name
ORDER BY 
    total_quantity_sold DESC, avg_order_value DESC
LIMIT 50;
