WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice,
           p_comment, CAST(NULL AS VARCHAR(55)) AS parent, 1 AS depth
    FROM part
    WHERE p_size > 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, 
           p.p_retailprice, p.p_comment, ph.p_partkey, ph.depth + 1
    FROM part p
    JOIN PartHierarchy ph ON ph.p_partkey = p.p_partkey
    WHERE ph.depth < 3
),
SupplierInfo AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal, COUNT(*) AS supplier_count
    FROM supplier
    GROUP BY s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           l.l_discount, c.c_mktsegment,
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE l.l_shipdate < o.o_orderdate
)
SELECT n.n_name, 
       COALESCE(SUM(p.p_retailprice) FILTER (WHERE li.l_partkey IS NOT NULL), 0) AS total_retailprice,
       AVG(pi.total_spent) OVER (PARTITION BY n.n_nationkey) AS avg_spent_per_customer,
       pi.order_count AS high_order_count
FROM nation n
LEFT JOIN SupplierInfo si ON n.n_nationkey = si.s_nationkey
LEFT JOIN PartHierarchy p ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
LEFT JOIN CustomerOrders pi ON pi.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = n.n_nationkey
    ORDER BY c.c_acctbal DESC
    LIMIT 1
)
LEFT JOIN LineItemDetails li ON li.l_partkey = p.p_partkey
GROUP BY n.n_name, pi.order_count
HAVING SUM(li.l_quantity) > 10
ORDER BY total_retailprice DESC, n.n_name;
