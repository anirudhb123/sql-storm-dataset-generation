WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
top_orders AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        ranked_orders o
    WHERE 
        o.order_rank <= 5
),
average_supply_cost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    to.o_orderkey,
    to.o_orderstatus,
    to.o_totalprice,
    to.o_orderdate,
    avgsc.avg_supply_cost
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    top_orders to ON o.o_orderkey = to.o_orderkey
JOIN 
    average_supply_cost avgsc ON p.p_partkey = avgsc.ps_partkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01' 
    AND l.l_shipdate < DATE '2023-12-31'
ORDER BY 
    to.o_orderstatus, 
    to.o_totalprice DESC;
