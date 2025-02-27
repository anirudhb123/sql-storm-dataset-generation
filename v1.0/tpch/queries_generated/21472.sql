WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 1 AS depth
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, depth + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_nationkey = cc.c_nationkey
    WHERE c.custkey <> cc.c_custkey
    AND cc.depth < 10
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierRegions AS (
    SELECT s.s_suppkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_suppkey, r.r_name
),
CombinedStats AS (
    SELECT c.c_name, c.c_acctbal, p.p_name,
           COALESCE(ps.total_availqty, 0) AS total_available,
           COALESCE(ps.avg_supplycost, 0) AS avg_cost,
           COALESCE(os.item_count, 0) AS total_items,
           COALESCE(os.total_price, 0.00) AS total_price,
           sr.nation_count
    FROM CustomerCTE c
    LEFT JOIN PartSupplierStats ps ON c.custkey = ps.ps_partkey
    LEFT JOIN OrderStats os ON c.custkey = os.o_orderkey
    LEFT JOIN SupplierRegions sr ON c.c_nationkey = sr.s_suppkey
    WHERE (ps.total_availqty IS NULL OR ps.total_availqty < 100) 
          AND sr.nation_count > 3 
          AND (c.c_acctbal + sr.nation_count) BETWEEN 1000 AND 5000
)
SELECT cb.c_name, cb.total_available, 
       CASE 
           WHEN cb.total_price > 1000 THEN 'High Value'
           WHEN cb.total_price BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS value_category,
       STRING_AGG(DISTINCT cb.p_name, ', ') AS parts_list,
       MAX(cb.avg_cost) OVER (PARTITION BY cb.c_name) AS max_avg_cost
FROM CombinedStats cb
GROUP BY cb.c_name, cb.total_available
HAVING COUNT(cb.p_name) > 2
ORDER BY cb.total_available DESC, cb.c_name;
