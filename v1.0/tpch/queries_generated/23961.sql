WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
),
PartSupplierSummary AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
SupplierData AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           COALESCE(NULLIF(SUM(l.l_discount * l.l_extendedprice), 0), 1) AS total_discounted_sales
    FROM supplier s
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND 
          o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
)
SELECT r.r_name, 
       ns.total_available_qty, 
       SUM(CASE WHEN sds.total_discounted_sales IS NOT NULL THEN sds.total_discounted_sales ELSE 0 END) AS total_discounted_sales,
       COALESCE(MAX(cos.total_spent), 0) AS max_customer_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierData sds ON n.n_nationkey = sds.s_nationkey
LEFT JOIN PartSupplierSummary ns ON ns.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty < 100)
LEFT JOIN CustomerOrderStats cos ON cos.order_count > 1
WHERE r.r_name NOT IN (SELECT r_name FROM region WHERE r_regionkey IS NULL)
GROUP BY r.r_name, ns.total_available_qty
ORDER BY r.r_name, ns.total_available_qty DESC
LIMIT 10 OFFSET 5;
