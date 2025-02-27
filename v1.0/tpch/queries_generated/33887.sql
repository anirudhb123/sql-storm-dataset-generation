WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal < 1000)
    WHERE oh.depth < 5
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, AVG(s.s_acctbal) AS avg_balance, 
           COUNT(*) FILTER (WHERE s.s_acctbal > 10000) AS high_balance_count
    FROM supplier s
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    oh.o_orderkey,
    COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY oh.o_orderkey) AS lineitem_count,
    COALESCE(cd.order_count, 0) AS customer_order_count,
    COALESCE(cd.total_spent, 0.00) AS total_spent_by_customer,
    p.p_name,
    DENSE_RANK() OVER (ORDER BY pd.total_available DESC) AS availability_rank,
    sd.s_name,
    sd.avg_balance
FROM OrderHierarchy oh
LEFT JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN PartDetails pd ON l.l_partkey = pd.p_partkey
LEFT JOIN CustomerOrders cd ON oh.o_orderkey = cd.c_custkey
LEFT JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE oh.o_totalprice > 1000
ORDER BY oh.o_orderdate DESC, availability_rank ASC
LIMIT 100;
