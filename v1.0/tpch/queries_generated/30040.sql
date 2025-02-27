WITH RECURSIVE PriceHistory AS (
    SELECT l_orderkey, l_partkey, l_extendedprice, l_discount, l_shipdate,
           ROW_NUMBER() OVER (PARTITION BY l_partkey ORDER BY l_shipdate) AS rn
    FROM lineitem
    WHERE l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS supply_count
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment, c.c_nationkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, c.c_mktsegment, c.c_nationkey
)
SELECT ns.n_name AS nation_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(o.total_sales) AS total_revenue,
       AVG(o.avg_price) AS avg_order_price,
       CASE WHEN SUM(o.total_sales) > 100000 THEN 'High Revenue'
            ELSE 'Normal Revenue' END AS revenue_category,
       COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance
FROM OrderDetails o
JOIN nation ns ON ns.n_nationkey = o.c_nationkey
LEFT JOIN SupplierDetails s ON s.supp_count > 5
WHERE o.total_sales IS NOT NULL
GROUP BY ns.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC
LIMIT 10;
