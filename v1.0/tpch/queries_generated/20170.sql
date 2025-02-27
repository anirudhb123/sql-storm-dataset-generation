WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, 
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_acctbal,
           SUM(o.o_totalprice) OVER (PARTITION BY c.c_custkey) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
), 
SupplierPricing AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           CASE 
               WHEN ps.ps_supplycost IS NULL THEN 0 
               ELSE ps.ps_supplycost * 1.05 
           END AS adjusted_cost,
           COALESCE(AVG(ps.ps_availqty) OVER (PARTITION BY ps.ps_suppkey), 0) AS avg_avail_qty
    FROM partsupp ps
), 
OrderDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT rc.c_name, 
       rc.total_spent, 
       COALESCE(SUM(sp.adjusted_cost * pd.avg_avail_qty), 0) AS total_supplier_cost,
       COUNT(DISTINCT od.l_orderkey) AS total_orders,
       CASE 
           WHEN SUM(od.total_line_price) IS NULL THEN 'No orders'
           WHEN SUM(od.total_line_price) > 10000 AND rc.rank_acctbal = 1 THEN 'Top Spender'
           ELSE 'Regular Customer'
       END AS customer_category
FROM RankedCustomers rc
LEFT JOIN SupplierPricing sp ON rc.c_custkey = sp.ps_suppkey
LEFT JOIN OrderDetails od ON rc.c_custkey = od.l_orderkey
WHERE rc.rank_acctbal <= 3 AND rc.total_spent > 5000
GROUP BY rc.c_name, rc.total_spent;
