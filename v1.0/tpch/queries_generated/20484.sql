WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supply_analysis AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY r.r_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    CASE 
        WHEN co.order_count IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COALESCE(co.total_spent, 0) AS total_spent,
    rs.s_name AS top_supplier,
    sa.total_supply_cost,
    sa.total_sales,
    sa.total_sales - sa.total_supply_cost AS profit_margin
FROM customer_orders co
LEFT JOIN ranked_suppliers rs ON rs.supplier_rank = 1
LEFT JOIN supply_analysis sa ON sa.total_supply_cost IS NOT NULL
WHERE (co.total_spent > 1000 OR co.order_count > 5)
  AND (sa.total_supply_cost IS NOT NULL OR sa.total_sales IS NULL)
ORDER BY co.c_custkey, profit_margin DESC;

