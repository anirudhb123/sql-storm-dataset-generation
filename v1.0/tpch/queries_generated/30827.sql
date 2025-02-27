WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.order_level + 1
    FROM 
        orders o
    INNER JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
nations_with_customers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS num_customers
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_receiptdate DESC) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    ss.s_name,
    ss.total_available,
    ss.avg_supply_cost,
    nwc.n_name,
    nwc.num_customers,
    ls.total_revenue
FROM 
    order_hierarchy oh
LEFT JOIN 
    supplier_summary ss ON ss.total_available >= 100
JOIN 
    nations_with_customers nwc ON nwc.num_customers > 50
LEFT JOIN 
    lineitem_summary ls ON ls.l_orderkey = oh.o_orderkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM lineitem l
        WHERE l.l_orderkey = oh.o_orderkey AND l.l_returnflag = 'R'
    )
AND 
    ls.rn = 1
ORDER BY 
    oh.o_orderdate DESC, oh.o_totalprice DESC
LIMIT 100;
