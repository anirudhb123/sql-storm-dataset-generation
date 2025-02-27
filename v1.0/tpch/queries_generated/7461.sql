WITH SupplierAggregate AS (
    SELECT s_suppkey, s_name, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM supplier
    JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY s_suppkey, s_name
),
OrderAggregate AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count, SUM(o_totalprice) AS total_spent
    FROM orders
    GROUP BY o_custkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.order_count, o.total_spent
    FROM customer c
    LEFT JOIN OrderAggregate o ON c.c_custkey = o.o_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
FinalReport AS (
    SELECT cs.c_name, cs.c_acctbal, n.n_name, sa.total_cost, cs.order_count, cs.total_spent
    FROM CustomerDetails cs
    JOIN SupplierAggregate sa ON cs.c_custkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand = 'Brand#23')))
    JOIN NationRegion n ON cs.c_custkey = n.n_nationkey
    WHERE cs.total_spent IS NOT NULL AND cs.order_count > 5
)
SELECT *
FROM FinalReport
ORDER BY total_spent DESC, c_acctbal DESC
LIMIT 10;
