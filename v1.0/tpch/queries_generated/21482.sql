WITH RecursiveSupplier AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS varchar(255)) AS full_name
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CAST(CONCAT(rs.full_name, ' > ', s.s_name) AS varchar(255))
    FROM supplier s
    JOIN RecursiveSupplier rs ON s.s_nationkey = rs.s_nationkey
    WHERE s.s_acctbal < rs.s_acctbal
),
NationDetails AS (
    SELECT n_name, COUNT(DISTINCT s_suppkey) AS supplier_count,
           SUM(s_acctbal) AS total_acctbal,
           CASE WHEN COUNT(DISTINCT s_suppkey) = 0 THEN NULL ELSE SUM(s_acctbal) / COUNT(DISTINCT s_suppkey) END AS avg_acctbal
    FROM supplier
    JOIN nation ON supplier.s_nationkey = nation.n_nationkey
    GROUP BY n_name
),
PartStats AS (
    SELECT p_brand, p_type, AVG(p_retailprice) AS avg_price, SUM(ps_availqty) AS total_availqty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY p_brand, p_type
),
OrderSummary AS (
    SELECT c.c_name, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '365 days'
    GROUP BY c.c_name, c.c_nationkey
),
FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM lineitem l
    WHERE l.l_tax > 0.1
    GROUP BY l.l_orderkey
)
SELECT nd.n_name,
       COALESCE(fd.total_spent, 0) AS total_spent_last_year,
       ps.avg_price,
       CASE WHEN fd.total_spent IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status,
       ps.total_availqty,
       COUNT(DISTINCT rs.suppkey) AS related_suppliers
FROM NationDetails nd
LEFT JOIN OrderSummary fd ON nd.n_name = fd.c_name
JOIN PartStats ps ON ps.avg_price > 50
LEFT JOIN RecursiveSupplier rs ON rs.s_nationkey = nd.supplier_count
GROUP BY nd.n_name, fd.total_spent, ps.avg_price, ps.total_availqty
HAVING COALESCE(fd.total_spent, 0) > 1000
ORDER BY nd.n_name ASC, ps.avg_price DESC;
