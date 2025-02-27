WITH RECURSIVE CustAgg AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
FilteredParts AS (
    SELECT p.p_partkey,
           p.p_name,
           COALESCE(ps.ps_availqty, 0) AS available_quantity,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 10
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    AND o.o_totalprice IS NOT NULL
),
NationStats AS (
    SELECT n.n_regionkey,
           COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
           AVG(c.c_acctbal) AS avg_customer_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_regionkey
)
SELECT ca.c_name,
       fp.p_name AS popular_part,
       hs.s_name AS top_supplier,
       o.price_rank,
       ns.avg_customer_balance
FROM CustAgg ca
JOIN FilteredParts fp ON fp.available_quantity > 50
JOIN RankedSuppliers hs ON hs.supplier_rank = 1
LEFT JOIN HighValueOrders o ON o.o_orderkey = ca.c_custkey
JOIN NationStats ns ON ns.n_regionkey = ca.c_nationkey
WHERE ca.total_spent > 5000
  AND (hs.s_name LIKE '%Corp%' OR hs.s_name IS NULL)
ORDER BY ca.rank, fp.total_supplycost DESC, o.o_totalprice DESC;
