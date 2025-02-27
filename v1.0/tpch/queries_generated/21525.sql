WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS total_returns
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, COUNT(l.l_linenumber) AS line_count,
           MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_line_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2022-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING COUNT(l.l_linenumber) > 5
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           (SELECT COUNT(*) FROM partsupp p WHERE p.ps_partkey = ps.ps_partkey) AS supplier_count
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
),
FinalReport AS (
    SELECT c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice) AS total_value,
           COALESCE(AVG(s.s_acctbal) FILTER (WHERE r.rank <= 10), 0) AS avg_top_supplier_balance,
           STRING_AGG(DISTINCT s.s_name, ', ') AS top_suppliers
    FROM CustomerOrderDetails c
    LEFT JOIN HighValueOrders h ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = h.o_orderkey)
    LEFT JOIN RankedSuppliers s ON h.o_orderkey IN (SELECT DISTINCT ps.ps_partkey FROM SupplierPartDetails ps WHERE ps.ps_suppkey = s.s_suppkey)
    GROUP BY c.c_name
)
SELECT r.r_name, fr.order_count, fr.total_value, fr.avg_top_supplier_balance, fr.top_suppliers
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey, SUM(fr.order_count) AS order_count,
           SUM(fr.total_value) AS total_value,
           AVG(fr.avg_top_supplier_balance) AS avg_top_supplier_balance,
           STRING_AGG(fr.top_suppliers, '; ') AS top_suppliers
    FROM FinalReport fr
    JOIN customer c ON fr.c_name = c.c_name
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey
) AS fr ON r.r_regionkey = fr.n_regionkey
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name;
