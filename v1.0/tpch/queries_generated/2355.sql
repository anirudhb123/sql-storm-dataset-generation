WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) as total_price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerAggregate AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name 
    FROM CustomerAggregate c 
    WHERE c.total_spent > 10000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, 
           (p.p_retailprice * ps.ps_availqty) AS total_value
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT DISTINCT hvc.c_name, 
       COUNT(DISTINCT lo.l_orderkey) AS order_count,
       SUM(lo.l_extendedprice) AS total_order_value,
       AVG(r.total_available_qty) AS avg_available_qty,
       STRING_AGG(DISTINCT pd.p_name, ', ') AS supplied_parts
FROM lineitem lo
JOIN RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
JOIN HighValueCustomers hvc ON lo.l_suppkey = hvc.c_custkey
LEFT JOIN SupplierStats r ON lo.l_suppkey = r.s_suppkey
LEFT JOIN PartDetails pd ON lo.l_partkey = pd.p_partkey
WHERE ro.total_price_rank <= 3
GROUP BY hvc.c_custkey, hvc.c_name
HAVING SUM(lo.l_extendedprice) > 5000
ORDER BY total_order_value DESC;
