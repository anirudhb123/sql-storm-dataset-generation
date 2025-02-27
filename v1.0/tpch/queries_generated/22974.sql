WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -3, GETDATE())
),
supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
final_report AS (
    SELECT 
        r.r_name AS region,
        nn.n_name AS nation,
        c.c_name AS customer_name,
        COUNT(DISTINCT ro.o_orderkey) AS recent_order_count,
        SUM(spsi.p_retailprice) AS total_part_value,
        AVG(spsi.ps_supplycost) AS avg_supply_cost
    FROM region r
    JOIN nation nn ON nn.n_regionkey = r.r_regionkey
    LEFT JOIN customer_order_summary c ON nu.c_custkey = c.c_custkey
    LEFT JOIN ranked_orders ro ON c.total_orders > 0 AND ro.o_orderkey IN (
        SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F'
    )
    LEFT JOIN supplier_part_info spsi ON c.c_name LIKE CONCAT('%', spsi.s_name, '%')
    WHERE 
        spsi.cost_rank <= 3
        AND (spsi.ps_availqty IS NOT NULL AND spsi.ps_availqty > 0)
    GROUP BY r.r_name, nn.n_name, c.c_name
)
SELECT 
    *,
    CASE 
        WHEN recent_order_count = 0 THEN 'No recent orders'
        ELSE 'Recent orders found'
    END AS order_status
FROM final_report
ORDER BY avg_supply_cost DESC, total_part_value ASC;
