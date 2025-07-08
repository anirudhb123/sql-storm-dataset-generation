WITH RECURSIVE CustomerOrderCTE AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrderCTE co ON o.o_custkey = co.c_custkey
    WHERE co.o_orderdate < o.o_orderdate
),
TotalSpendCTE AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
TopSpenders AS (
    SELECT c.c_custkey, c.c_name, ts.total_spent,
           RANK() OVER (ORDER BY ts.total_spent DESC) AS spending_rank
    FROM TotalSpendCTE ts
    JOIN customer c ON ts.c_custkey = c.c_custkey
    WHERE ts.total_spent > 1000
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT s.s_name, COUNT(DISTINCT co.o_orderkey) AS order_count, 
       SUM(co.o_totalprice) AS total_order_value, 
       pd.p_name, pd.ps_supplycost, pd.ps_availqty
FROM CustomerOrderCTE co
JOIN supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'USA%')
LEFT JOIN ProductDetails pd ON pd.rank = 1
WHERE co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
GROUP BY s.s_name, pd.p_name, pd.ps_supplycost, pd.ps_availqty
HAVING COUNT(DISTINCT co.o_orderkey) > 10
ORDER BY total_order_value DESC
LIMIT 50;