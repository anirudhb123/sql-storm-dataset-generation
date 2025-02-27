WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           l.l_extendedprice * (1 - l.l_discount) AS net_price,
           l.l_returnflag
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
),
AggregatedSales AS (
    SELECT o.o_orderkey, SUM(hv.net_price) AS total_sales
    FROM HighValueLineItems hv
    JOIN orders o ON hv.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT ps.ps_suppkey, SUM(hv.net_price) AS supplier_total
    FROM partsupp ps
    JOIN HighValueLineItems hv ON ps.ps_partkey = hv.l_partkey
    GROUP BY ps.ps_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.supplier_total,
           COALESCE(ss.supplier_total, 0) AS valid_total
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
)
SELECT ns.n_name, COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
       SUM(ts.valid_total) AS total_supplier_sales,
       MAX(ts.valid_total) AS max_sales,
       MIN(ts.valid_total) AS min_sales
FROM nation ns
LEFT JOIN TopSuppliers ts ON ns.n_nationkey = ts.s_nationkey
WHERE ts.valid_total IS NOT NULL OR ts.s_suppkey IS NULL
GROUP BY ns.n_name
HAVING COUNT(ts.s_suppkey) > 0
ORDER BY supplier_count DESC, total_supplier_sales DESC;
