WITH RECURSIVE price_adjustments AS (
    SELECT ps_partkey, s_suppkey, ps_availqty, ps_supplycost * 1.1 AS adjusted_cost
    FROM partsupp
    WHERE ps_availqty > 100
    
    UNION ALL

    SELECT ps.partkey, ps.suppkey, ps.availqty, ps_supplycost * 0.9
    FROM partsupp ps
    JOIN price_adjustments pa ON pa.ps_partkey = ps.ps_partkey AND pa.s_suppkey = ps.ps_suppkey
    WHERE ps_availqty <= 100 AND pa.adjusted_cost IS NOT NULL
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_income,
           COUNT(l.l_orderkey) AS line_count, RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, r.r_name AS region, SUM(pa.adjusted_cost) AS total_cost
    FROM supplier s
    LEFT OUTER JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT OUTER JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN price_adjustments pa ON s.s_suppkey = pa.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    si.region AS supplier_region,
    si.s_name AS supplier_name,
    os.o_orderkey,
    os.total_income,
    os.line_count,
    CASE 
        WHEN os.rank <= 10 THEN 'Top Order'
        WHEN os.rank > 10 AND os.total_income IS NULL THEN 'No Income'
        ELSE 'Regular Order'
    END AS order_classification,
    COALESCE(SUM(CASE WHEN si.total_cost IS NULL THEN 0 ELSE si.total_cost END), 0) AS supplier_cost_total
FROM order_summary os
FULL OUTER JOIN supplier_info si ON os.o_orderkey = si.s_suppkey
GROUP BY si.region, si.s_name, os.o_orderkey, os.total_income, os.line_count, os.rank
HAVING SUM(si.total_cost) IS NOT NULL
ORDER BY 1, 2, 3 DESC;
