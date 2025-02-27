WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ps.ps_availqty, ps.ps_supplycost, 
           p.p_partkey, p.p_name, p.p_container,
           1 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ps.ps_availqty, ps.ps_supplycost, 
           p.p_partkey, p.p_name, p.p_container,
           sc.level + 1
    FROM SupplyChain sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE sc.level < 5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           SUM(ts.total_sales) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN TotalSales ts ON o.o_orderkey = ts.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT cs.c_custkey, cs.c_name, cs.order_count, cs.total_spent,
           RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSales cs
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    COALESCE(rc.order_count, 0) AS total_orders,
    COALESCE(rc.total_spent, 0.00) AS amount_spent,
    COALESCE(sc.s_acctbal, 0.00) AS supplier_acct_bal
FROM RankedCustomers rc
LEFT JOIN SupplyChain sc ON sc.p_partkey IN (
    SELECT p_partkey 
    FROM part 
    WHERE p_size <= 20
)
WHERE rc.rank <= 10
ORDER BY rc.total_spent DESC;
