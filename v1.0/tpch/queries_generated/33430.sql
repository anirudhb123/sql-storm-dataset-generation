WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.level + 1
    FROM supplier s
    JOIN SupplierCTE c ON c.s_suppkey = s.s_suppkey
    WHERE c.level < 3
),
OrderSums AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, s.s_suppkey, s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 20.00
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    r.n_name AS nation_name,
    p.p_name AS part_name,
    SUM(o.total_price) AS total_order_value,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_acctbal,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY r.n_name ORDER BY total_order_value DESC) AS region_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN PartSupplier p ON n.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = p.s_suppkey LIMIT 1)
JOIN OrderSums o ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s_suppkey FROM SupplierCTE))
LEFT JOIN RankedCustomers c ON o.o_orderkey = c.c_custkey
GROUP BY r.n_name, p.p_name
HAVING SUM(o.total_price) > 10000
ORDER BY region_rank, total_order_value DESC;
