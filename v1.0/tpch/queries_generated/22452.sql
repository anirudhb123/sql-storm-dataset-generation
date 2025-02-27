WITH RECURSIVE supply_data AS (
    SELECT
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank
    FROM partsupp
), order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
), customer_region AS (
    SELECT
        c.c_custkey,
        c.c_name,
        r.r_name AS region
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), suppliers_details AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments available') AS supplier_comment
    FROM supplier s
)
SELECT
    cr.region,
    SUM(os.total_revenue) AS total_revenue_per_region,
    AVG(CASE WHEN sd.rank = 1 THEN ps_supplycost END) AS avg_top_supplycost,
    COUNT(DISTINCT cd.c_custkey) AS total_customers,
    MAX(sd.ps_availqty) AS max_avail_qty,
    STRING_AGG(DISTINCT sd.supplier_comment, '; ') AS supplier_comments
FROM order_summary os
JOIN customer_region cr ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'C%')
)
LEFT JOIN supply_data sd ON os.o_orderkey = sd.ps_partkey
JOIN suppliers_details cd ON sd.ps_suppkey = cd.s_suppkey
GROUP BY cr.region
HAVING total_revenue_per_region > (
    SELECT AVG(total_revenue) FROM order_summary
    WHERE o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
) OR COUNT(DISTINCT cd.c_custkey) > 50
ORDER BY total_revenue_per_region DESC, cr.region ASC;
