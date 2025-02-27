WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
      AND n.n_name NOT LIKE '%land%'
),
PartStats AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supply_count, MAX(p.p_retailprice) AS max_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS orders_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal < (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY c.c_custkey
),
OrderLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM lineitem l
    WHERE l.l_shipdate > '1994-01-01'
      AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    COALESCE(cs.total_spent, 0) AS customer_spent,
    ps.max_price AS part_max_price,
    ps.supply_count,
    ol.total_price_after_discount
FROM RankedSuppliers r
FULL OUTER JOIN CustomerOrders cs ON r.rank = cs.orders_count
LEFT JOIN PartStats ps ON r.s_suppkey = ps.p_partkey
LEFT JOIN OrderLineItems ol ON ol.l_orderkey = cs.total_spent::integer
WHERE r.rank <= 5
  AND (cs.total_spent IS NULL OR cs.total_spent >= 1000)
  AND (ps.supply_count > 1 OR ps.max_price IS NULL)
ORDER BY r.s_suppkey, customer_spent DESC NULLS LAST;
