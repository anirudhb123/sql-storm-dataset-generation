WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name,
           p.p_brand,
           p.p_type,
           p.p_size,
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
SuppliersWithComment AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           CASE 
               WHEN s.s_comment LIKE '%urgent%' THEN 'Important Supplier'
               WHEN s.s_comment IS NULL THEN 'No Comment'
               ELSE 'Regular Supplier'
           END AS supplier_status
    FROM supplier s
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT r.r_name AS region_name, 
       c.c_name AS customer_name, 
       o.order_count, 
       o.total_spent,
       p.p_name,
       p.p_retailprice,
       s.s_name AS supplier_name,
       s.supplier_status,
       COALESCE(l.total_late_shipments, 0) AS late_shipments
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN CustomerOrders o ON c.c_custkey = o.c_custkey
JOIN lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
LEFT JOIN RankedParts p ON l.l_partkey = p.p_partkey AND p.rn <= 3
JOIN SuppliersWithComment s ON l.l_suppkey = s.s_suppkey
LEFT JOIN (
    SELECT l.l_orderkey,
           COUNT(l.l_linenumber) AS total_late_shipments
    FROM lineitem l
    WHERE l.l_shipdate > l.l_commitdate
    GROUP BY l.l_orderkey
) AS late ON l.l_orderkey = late.l_orderkey
WHERE o.total_spent > 1000
ORDER BY r.r_name, o.total_spent DESC;
