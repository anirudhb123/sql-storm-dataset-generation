WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_supply, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost)) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey
), 

PriceBreakdown AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COALESCE(p.net_price, 0) AS total_spent,
           COUNT(o.o_orderkey) AS order_count, 
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN PriceBreakdown p ON o.o_orderkey = p.l_orderkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),

TopCustomers AS (
    SELECT *, 
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders
    WHERE total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrders 
        WHERE total_spent IS NOT NULL
    )
)

SELECT t.r, n.n_name, r.r_name, SUM(t.total_spent) AS total_spent_by_region
FROM TopCustomers t
JOIN nation n ON t.c_custkey % (SELECT COUNT(nation.n_nationkey) FROM nation) = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE t.rank <= 5
GROUP BY t.c_custkey, n.n_name, r.r_name
HAVING SUM(t.total_spent) > (SELECT AVG(total_spent) FROM TopCustomers) 
   OR EXISTS (
       SELECT 1 
       FROM LineItem li 
       WHERE li.l_orderkey IN (SELECT o.o_orderkey FROM Orders o WHERE o.o_custkey = t.c_custkey)
       AND li.l_returnflag = 'N'
   )
ORDER BY total_spent_by_region DESC;
