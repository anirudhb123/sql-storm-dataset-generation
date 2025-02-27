WITH RECURSIVE supplier_cte AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM supplier s
    INNER JOIN supplier_cte cte ON s.s_suppkey = cte.s_suppkey
    WHERE s.s_acctbal > cte.s_acctbal * 0.9
),
part_details AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
order_details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count,
        MAX(NULLIF(l.l_shipdate, l.l_commitdate)) AS delayed_shipment
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name LIKE 'A%'
),
final_results AS (
    SELECT 
        p.p_partkey,
        pd.supplier_count,
        pd.total_avail_qty,
        pd.avg_supply_cost,
        od.total_revenue,
        od.line_item_count,
        CASE 
            WHEN od.delayed_shipment IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS is_delayed,
        nr.n_name,
        ROW_NUMBER() OVER (PARTITION BY nr.n_name ORDER BY pd.total_avail_qty DESC) AS rn
    FROM part_details pd
    JOIN order_details od ON pd.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
    JOIN nation_region nr ON pd.supplier_count > 0
)
SELECT *
FROM final_results
WHERE rn <= 5
ORDER BY n_name, total_revenue DESC;
