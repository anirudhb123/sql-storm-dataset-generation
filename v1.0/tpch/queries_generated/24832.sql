WITH RECURSIVE SupplierRankings AS (
    SELECT s_suppkey, s_name, s_acctbal, 
           RANK() OVER (PARTITION BY s_suppkey ORDER BY s_acctbal DESC) as rank
    FROM supplier
), 
HighValueClients AS (
    SELECT c_custkey, c_name, c_acctbal, 
           ROW_NUMBER() OVER (ORDER BY c_acctbal DESC) as rn
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
), 
QualifyingOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate,
           CASE 
               WHEN o_orderstatus = 'F' THEN 'Finalized'
               WHEN o_orderstatus = 'P' THEN 'Pending'
               ELSE 'Unknown' 
           END AS order_status
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01' AND o_orderdate < DATE '2024-01-01'
), 
LineItemQuantities AS (
    SELECT l_orderkey, SUM(l_quantity) AS total_quantity,
           COUNT(DISTINCT l_returnflag) AS distinct_return_flags
    FROM lineitem
    GROUP BY l_orderkey
)

SELECT
    p.p_partkey, p.p_name, 
    COALESCE(pr.s_name, 'No Supplier') as supplier_name,
    COALESCE(SUM(CASE WHEN li.l_discount > 0.1 THEN li.l_extendedprice END), 0) AS total_discounted_price,
    MAX(o.o_totalprice) AS max_order_value,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'F') AS finalized_order_count,
    SUM(DISTINCT CASE WHEN li.l_returnflag IS NULL THEN 1 ELSE 0 END) AS null_return_flags,
    COUNT(DISTINCT CASE WHEN ci.c_acctbal > 10000 THEN ci.c_custkey END) AS high_value_customers

FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier pr ON ps.ps_suppkey = pr.s_suppkey
FULL OUTER JOIN QualifyingOrders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal = pr.s_acctbal LIMIT 1) 
LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN LineItemQuantities lq ON li.l_orderkey = lq.l_orderkey
LEFT JOIN HighValueClients ci ON o.o_custkey = ci.c_custkey
WHERE p.p_size % 3 = 0 OR p.p_size IS NULL
GROUP BY p.p_partkey, p.p_name, pr.s_name
HAVING MAX(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate >= '2022-01-01')
ORDER BY p.p_partkey DESC, total_discounted_price ASC
LIMIT 100 OFFSET 10;
