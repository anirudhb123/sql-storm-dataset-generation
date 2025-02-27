WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name = 'USA'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sc.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    JOIN supply_chain sc ON s.s_nationkey = sc.n_nationkey
    WHERE o.o_totalprice > 1000 AND sc.level < 5
),
ranked_supply AS (
    SELECT s.s_name, s.s_acctbal, RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.r_regionkey = (
        SELECT r_regionkey 
        FROM region 
        WHERE r_name = 'North America'
    )
),
final_metrics AS (
    SELECT p.p_brand, p.p_type, 
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(COALESCE(s.s_acctbal, 0)) AS average_acctbal
    FROM part p
    JOIN lineitem li ON li.l_partkey = p.p_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    LEFT JOIN ranked_supply s ON s.s_name = o.o_clerk
    WHERE li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_brand, p.p_type
)
SELECT fm.p_brand, fm.p_type, 
       fm.total_sales, fm.order_count, 
       ROW_NUMBER() OVER (ORDER BY fm.total_sales DESC) AS sales_rank
FROM final_metrics fm
JOIN supply_chain sc ON sc.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
)
WHERE fm.order_count > 100
ORDER BY fm.sales_rank, fm.p_brand;
