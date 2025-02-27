WITH RECURSIVE order_summary AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderdate,
        o_totalprice,
        1 as level
    FROM 
        orders
    WHERE 
        o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        os.level + 1
    FROM 
        orders o
    JOIN 
        order_summary os ON o.o_orderkey = os.o_orderkey + 1
),
customer_ranked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank_in_nation
    FROM 
        customer c
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name
    FROM 
        customer_ranked c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.rank_in_nation <= 5
),
suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
),
aggregated_orders AS (
    SELECT 
        os.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue,
        COUNT(l.l_orderkey) as number_of_items
    FROM 
        order_summary os
    JOIN 
        lineitem l ON os.o_orderkey = l.l_orderkey
    GROUP BY 
        os.o_orderkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    a.total_revenue,
    a.number_of_items,
    r.r_name
FROM 
    top_customers c
LEFT JOIN 
    suppliers s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100.00))
JOIN 
    aggregated_orders a ON a.o_orderkey = c.c_custkey
JOIN 
    nation r ON c.c_nationkey = r.n_nationkey
WHERE 
    c.c_acctbal < ALL (SELECT c2.c_acctbal FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey AND c2.c_custkey <> c.c_custkey)
ORDER BY 
    c.c_name ASC;
