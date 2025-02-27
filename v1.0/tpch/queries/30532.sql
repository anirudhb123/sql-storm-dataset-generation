
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderDetails AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, cod.total_spent, cod.order_count,
           DENSE_RANK() OVER (ORDER BY cod.total_spent DESC) AS rank
    FROM customer c
    JOIN CustomerOrderDetails cod ON c.c_custkey = cod.c_custkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acct_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_type, 
       COALESCE(ps.total_avail_qty, 0) AS total_available_quantity,
       ps.avg_supply_cost,
       CASE 
           WHEN s.level IS NOT NULL THEN 'Part of Supply Chain'
           ELSE 'Independent Supplier' 
       END AS supplier_status,
       nc.supplier_count AS suppliers_in_nation,
       nc.total_acct_balance AS total_supplier_balance,
       tc.total_spent AS top_customer_spent
FROM part p
LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy s ON s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps)
LEFT JOIN NationStats nc ON p.p_partkey % 10 = nc.n_nationkey
LEFT JOIN TopCustomers tc ON tc.order_count > 100
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50)
  AND (p.p_comment IS NULL OR p.p_comment LIKE '%important%')
ORDER BY p.p_partkey, total_available_quantity DESC;
