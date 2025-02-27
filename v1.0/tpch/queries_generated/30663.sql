WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
top_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_spent) AS nation_total_spent
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        sales_summary ss ON c.c_custkey = ss.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty * ps.ps_supplycost) > 50000
)
SELECT 
    tn.n_name AS nation_name,
    hp.p_name AS part_name,
    COALESCE(ss.total_spent, 0) AS customer_total_spent,
    AVG(ss.total_orders) OVER (PARTITION BY tn.n_nationkey) AS avg_orders_per_customer,
    hp.total_value AS part_total_value
FROM 
    top_nations tn
CROSS JOIN 
    high_value_parts hp
LEFT JOIN 
    sales_summary ss ON tn.n_nationkey = ss.c_custkey
WHERE 
    tn.nation_total_spent > 100000
ORDER BY 
    tn.n_name, hp.total_value DESC;
