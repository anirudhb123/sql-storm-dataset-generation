WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'AFRICA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
SupplierStats AS (
    SELECT s.s_nationkey,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS average_account_balance
    FROM supplier s
    GROUP BY s.s_nationkey
), 
OrderSummary AS (
    SELECT o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
CustomerRanked AS (
    SELECT c.c_custkey,
           c.c_name,
           RANK() OVER (ORDER BY os.total_spent DESC) AS customer_rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT n.n_name AS nation_name,
       ss.supplier_count,
       ss.average_account_balance,
       cr.customer_rank,
       cr.c_name AS customer_name
FROM NationHierarchy n
LEFT OUTER JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN CustomerRanked cr ON cr.customer_rank <= 10
WHERE ss.supplier_count IS NOT NULL
ORDER BY n.n_name, cr.customer_rank;
