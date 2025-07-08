WITH RECURSIVE recent_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderstatus
    FROM orders
    WHERE o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM orders o
    JOIN recent_orders ro ON o.o_orderkey = ro.o_orderkey + 1
),
aggregated_data AS (
    SELECT 
        p.p_brand,
        p.p_type,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(s.s_acctbal) AS average_supplier_balance,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS brand_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY p.p_brand, p.p_type
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
nation_data AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT 
    a.p_brand,
    a.p_type,
    a.total_revenue,
    a.average_supplier_balance,
    n.n_name,
    n.customer_count,
    n.total_order_value,
    RANK() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank
FROM aggregated_data a
FULL OUTER JOIN nation_data n ON a.p_brand = n.n_name
WHERE n.customer_count IS NOT NULL
  AND (a.average_supplier_balance IS NULL OR a.average_supplier_balance > 500)
ORDER BY a.p_brand, n.n_name;