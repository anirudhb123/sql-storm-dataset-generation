WITH RECURSIVE price_history AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty,
        ps_supplycost,
        1 AS level
    FROM 
        partsupp
    WHERE 
        ps_availqty > 0
    UNION ALL
    SELECT 
        pp.ps_partkey, 
        pp.ps_suppkey, 
        pp.ps_availqty,
        pp.ps_supplycost * (1 + (level * 0.1)) AS updated_cost,
        level + 1
    FROM 
        partsupp pp
    JOIN 
        price_history ph ON pp.ps_partkey = ph.ps_partkey
    WHERE 
        pp.ps_availqty > ph.ps_availqty AND level < 10
),
filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice > 0
),
nation_customers AS (
    SELECT 
        n.n_nationkey,
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_nationkey, c.c_custkey, c.c_name
),
final_result AS (
    SELECT 
        n.r_name,
        SUM(ph.updated_cost) AS total_cost,
        AVG(nc.total_spent) FILTER (WHERE nc.total_spent IS NOT NULL) AS avg_spent
    FROM 
        region n
    LEFT JOIN 
        nation_customers nc ON n.r_regionkey = (SELECT n.n_regionkey 
                                                 FROM nation n 
                                                 WHERE n.n_nationkey = nc.n_nationkey)
    LEFT JOIN 
        price_history ph ON nc.c_custkey = ph.ps_suppkey
    GROUP BY 
        n.r_name
    HAVING 
        avg_spent IS NOT NULL OR total_cost > 100
)
SELECT 
    r_name,
    total_cost,
    avg_spent,
    CASE 
        WHEN avg_spent IS NULL THEN 'No Purchases'
        WHEN avg_spent < 100 THEN 'Low Spend'
        ELSE 'High Spend'
    END AS spending_category
FROM 
    final_result
ORDER BY 
    total_cost DESC, avg_spent ASC NULLS LAST;
