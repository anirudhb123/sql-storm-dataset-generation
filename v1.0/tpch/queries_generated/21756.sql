WITH RECURSIVE Region_Nation AS (
    SELECT n.n_nationkey, r.r_name, n.n_name, 0 AS level
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    UNION ALL
    SELECT n.n_nationkey, r.r_name, n.n_name, level + 1
    FROM nation n
    JOIN Region_Nation rn ON n.n_nationkey = rn.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE level < 2
), Supplier_Stats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), Order_Summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(*) OVER (PARTITION BY o.o_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY o.o_orderkey
), Customer_Totals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_orders,
           COUNT(DISTINCT o.o_orderkey) AS total_order_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)

SELECT crn.r_name, crn.n_name, ss.total_avail_qty, ss.avg_supply_cost,
       os.total_price, os.item_count, ct.total_orders, ct.total_order_count, 
       ct.last_order_date
FROM Region_Nation crn
LEFT JOIN Supplier_Stats ss ON crn.n_nationkey = ss.s_suppkey
JOIN Order_Summary os ON ss.s_suppkey = os.o_orderkey
FULL OUTER JOIN Customer_Totals ct ON os.o_orderkey = ct.c_custkey
WHERE (ss.total_avail_qty IS NULL OR ct.total_orders IS NOT NULL)
  AND (crn.level = 1 OR crn.n_name LIKE 'A%')
ORDER BY crn.r_name, ct.last_order_date DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
