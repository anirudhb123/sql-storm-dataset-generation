WITH RECURSIVE price_history AS (
    SELECT 
        p_partkey,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_partkey ORDER BY p_retailprice) AS price_rank
    FROM part
    WHERE p_retailprice IS NOT NULL
),
region_supplier AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
qualified_parts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 10
),
final_report AS (
    SELECT 
        COALESCE(rs.r_name, 'Unknown Region') AS region,
        SUM(co.total_spent) AS total_revenue,
        COUNT(DISTINCT co.c_custkey) AS customer_count,
        SUM(CASE WHEN ph.price_rank = 1 THEN ph.p_retailprice ELSE 0 END) AS min_price,
        MAX(ph.p_retailprice) AS max_price,
        COUNT(DISTINCT qp.ps_partkey) AS qualified_parts
    FROM region_supplier rs
    FULL OUTER JOIN customer_orders co ON rs.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN customer c ON n.n_nationkey = c.c_nationkey WHERE c.c_custkey = co.c_custkey)
    FULL OUTER JOIN price_history ph ON ph.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM qualified_parts qp WHERE qp.total_avail_qty > 0)
    FULL OUTER JOIN qualified_parts qp ON TRUE
    GROUP BY rs.r_name
    ORDER BY total_revenue DESC
)
SELECT 
    *,
    CASE 
        WHEN total_revenue IS NULL THEN 'No Revenue'
        WHEN total_revenue > 100000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 10000 AND 100000 THEN 'Moderate Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM final_report
WHERE region IS NOT NULL OR customer_count > 0;
