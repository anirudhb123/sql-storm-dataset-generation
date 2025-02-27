WITH RECURSIVE supplier_cte AS (
    SELECT s_suppkey, s_name, s_acctbal, n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s_suppkey, s_name, s_acctbal, n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN supplier_cte ON s.s_suppkey < supplier_cte.s_suppkey
), ranked_lineitems AS (
    SELECT 
        l.*,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS row_num,
        SUM(l_extendedprice * (1 - l_discount)) OVER (PARTITION BY l_orderkey) AS total_order_value
    FROM lineitem l
    WHERE l_shipdate >= '2023-01-01'
), average_prices AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), aggregate_data AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
), enriched_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COALESCE(sd.total_spent, 0) AS total_spent_by_customer,
        CASE 
            WHEN COALESCE(sd.order_count, 0) > 5 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer'
        END AS customer_type
    FROM orders o
    LEFT JOIN aggregate_data sd ON o.o_custkey = sd.c_custkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    e.o_orderkey,
    e.o_totalprice,
    e.customer_type,
    r.nation_name,
    l.l_returnflag,
    COUNT(DISTINCT l.l_linenumber) AS distinct_line_items,
    AVG(ap.avg_supplycost) AS average_supply_cost
FROM enriched_orders e
LEFT JOIN ranked_lineitems l ON e.o_orderkey = l.l_orderkey AND l.row_num <= 5
LEFT JOIN supplier_cte r ON l.l_suppkey = r.s_suppkey
LEFT JOIN average_prices ap ON l.l_partkey = ap.p_partkey
GROUP BY 
    e.o_orderkey, 
    e.o_totalprice, 
    e.customer_type, 
    r.nation_name, 
    l.l_returnflag
HAVING 
    COUNT(DISTINCT l.l_linenumber) > 3
ORDER BY 
    e.o_totalprice DESC;
