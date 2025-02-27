WITH RECURSIVE date_range AS (
    SELECT DATE '2023-01-01' AS order_date
    UNION ALL
    SELECT order_date + INTERVAL '1 day'
    FROM date_range
    WHERE order_date < DATE '2023-12-31'
), 
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           (SELECT SUM(ps.ps_supplycost * ps.ps_availqty) 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey) AS total_supply_cost
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
), 
orders_tax AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS taxed_amount,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), 
nations_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name    
)
SELECT 
    pr.p_partkey, pr.p_name, pr.p_brand, pr.p_container,
    COALESCE(ss.total_supply_cost, 0) AS supplier_total_cost,
    ns.n_name AS nation_name, ns.supplier_count,
    ns.total_balance, 
    od.taxed_amount,
    DENSE_RANK() OVER (ORDER BY ns.total_balance DESC) AS balance_rank,
    CASE 
        WHEN od.taxed_amount IS NULL THEN 'No Orders' 
        ELSE 'Orders Exist' 
    END AS order_status,
    dd.order_date
FROM part pr
LEFT JOIN supplier_details ss ON pr.p_partkey = ss.s_suppkey -- Joining on an unconventional key
LEFT JOIN nations_summary ns ON ns.total_balance > 10000 -- Unusual filter for joining
LEFT JOIN orders_tax od ON od.rn = 1 -- Joining on a ranking condition
CROSS JOIN date_range dd
WHERE (pr.p_size IS NOT NULL AND pr.p_size < 30) 
   OR (pr.p_comment LIKE '%special%' AND pr.p_retailprice IS NOT NULL)
ORDER BY supplier_total_cost DESC, balance_rank;
