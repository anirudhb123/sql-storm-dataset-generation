WITH RECURSIVE price_changes AS (
    SELECT
        ps.partkey,
        s.suppkey,
        ps.ps_supplycost AS initial_cost,
        ps.ps_supplycost * 1.1 AS current_cost,
        0 AS change_count
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT
        pc.partkey,
        pc.suppkey,
        pc.current_cost,
        pc.current_cost * 1.1,
        pc.change_count + 1
    FROM
        price_changes pc
    WHERE
        pc.change_count < 5
),
avg_supplier_cost AS (
    SELECT
        p.p_partkey,
        AVG(pc.current_cost) AS avg_cost
    FROM
        part p
    JOIN
        price_changes pc ON p.p_partkey = pc.partkey 
    GROUP BY
        p.p_partkey
),
customer_orders AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
)
SELECT
    n.n_name,
    r.r_name,
    p.p_name,
    COALESCE(avg_cost, 0) AS avg_supply_cost,
    co.total_orders,
    co.total_spent,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)) AS total_lineitems,
    CASE WHEN co.total_orders > 10 THEN 'High Value' ELSE 'Low Value' END AS customer_value_segment
FROM
    nation n
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    customer_orders co ON co.c_custkey IN (SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    part p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0 ORDER BY ps.ps_supplycost DESC LIMIT 1)
LEFT JOIN
    avg_supplier_cost ac ON ac.p_partkey = p.p_partkey
WHERE
    n.n_name IS NOT NULL
ORDER BY
    n.n_name, r.r_name, co.total_spent DESC
LIMIT 100;
