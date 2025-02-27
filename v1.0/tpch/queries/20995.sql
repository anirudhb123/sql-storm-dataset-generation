WITH SupplierCost AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RankedCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           COALESCE(co.total_spent, 0) AS total_spent,
           COALESCE(co.order_count, 0) AS order_count,
           RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT r.r_name,
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(COALESCE(sc.total_supply_cost, 0)) AS total_cost,
       STRING_AGG(DISTINCT cust.c_name || ' (Total: ' || cust.total_spent || ', Orders: ' || cust.order_count || ')', '; ') AS customer_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN (
    SELECT sc.s_suppkey,
           SUM(sc.total_supply_cost) AS total_supply_cost
    FROM SupplierCost sc
    GROUP BY sc.s_suppkey
) AS sc ON sc.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_inner.ps_availqty)
        FROM partsupp ps_inner
        WHERE ps_inner.ps_partkey = (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_size BETWEEN 10 AND 20
            ORDER BY p.p_retailprice DESC
            LIMIT 1 OFFSET 2
        )
    )
)
LEFT JOIN RankedCustomers cust ON cust.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    LIMIT 1
)
WHERE r.r_name LIKE 'A%'
GROUP BY r.r_name
HAVING SUM(COALESCE(sc.total_supply_cost, 0)) > (
    SELECT SUM(ps.ps_supplycost)
    FROM partsupp ps
    WHERE ps.ps_availqty < 500
)
ORDER BY nation_count DESC, total_cost DESC;
