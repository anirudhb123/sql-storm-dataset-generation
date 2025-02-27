WITH ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
supply_summary AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
nation_filter AS (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_comment IS NOT NULL AND n.n_comment <> ''
),
important_suppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           CASE
               WHEN s.s_acctbal > 10000 THEN 'High'
               WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
               ELSE 'Low'
           END AS account_level
    FROM supplier s
    WHERE s.s_comment LIKE '%reliable%' OR s.s_comment IS NULL
),
performance_benchmark AS (
    SELECT l.l_orderkey,
           l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count,
           MIN(l.l_shipdate) AS first_ship_date,
           MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    LEFT JOIN important_suppliers isup ON l.l_suppkey = isup.s_suppkey
    WHERE l.l_returnflag = 'N' AND l.l_shipdate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY l.l_orderkey, l.l_partkey
    HAVING COUNT(DISTINCT l.l_suppkey) > 1
)
SELECT o.order_rank, 
       o.o_orderkey, 
       o.o_orderdate, 
       o.o_totalprice, 
       p.p_name,
       ss.total_avail_qty,
       ss.avg_supply_cost,
       pf.s_name AS supplier_name,
       pf.account_level,
       COALESCE(b.total_price, 0) AS lineitem_total_price,
       COUNT(DISTINCT n.n_nationkey) OVER () AS unique_nations_count
FROM ranked_orders o
JOIN part p ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM supply_summary ss
    WHERE ss.total_avail_qty > 100
    INTERSECT
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_shipdate >= DATEADD(MONTH, -1, GETDATE())
) 
LEFT JOIN important_suppliers pf ON pf.s_suppkey = (
    SELECT TOP 1 l.l_suppkey
    FROM lineitem l
    WHERE l.l_orderkey = o.o_orderkey
    ORDER BY l.l_extendedprice DESC
)
LEFT JOIN performance_benchmark b ON b.l_orderkey = o.o_orderkey
JOIN nation_filter n ON EXISTS (
    SELECT 1
    FROM nation nn
    WHERE nn.n_nationkey = pf.s_nationkey
) 
WHERE o.o_totalprice > 1000
ORDER BY o.o_orderdate DESC, o.o_orderkey;
