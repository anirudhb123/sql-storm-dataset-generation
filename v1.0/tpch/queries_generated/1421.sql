WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
CustomerStatistics AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    ns.n_name,
    SUM(ls.revenue) AS total_revenue,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    AVG(cs.total_spent) AS avg_spent_per_customer,
    COUNT(o.o_orderkey) AS total_orders
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerStatistics cs ON o.o_custkey = cs.c_custkey
LEFT JOIN 
    LineItemStats ls ON li.l_orderkey = ls.l_orderkey
WHERE 
    p.p_retailprice > 50 
    AND ns.r_name IS NOT NULL 
GROUP BY 
    ns.n_name
HAVING 
    SUM(ls.revenue) > 100000
ORDER BY 
    total_revenue DESC;
