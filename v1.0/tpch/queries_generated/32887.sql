WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 as level
    FROM customer
    WHERE c_acctbal > 1000 
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 1000 AND ch.level < 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, RANK() OVER (ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal > 5000
),
PartSupplierData AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, p.p_brand
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 20.00
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) as total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    ch.c_name,
    ch.c_acctbal,
    COUNT(DISTINCT od.o_orderkey) AS order_count,
    SUM(od.total_price) AS total_order_value,
    COALESCE(SUM(PSD.ps_availqty), 0) AS total_available_qty,
    MAX(ts.rank) AS supplier_rank
FROM CustomerHierarchy ch
LEFT JOIN OrderDetails od ON ch.c_custkey = od.o_custkey
LEFT JOIN PartSupplierData PSD ON od.o_orderkey = PSD.p_partkey
LEFT JOIN TopSuppliers ts ON PSD.p_brand = ts.s_name
WHERE ch.level < 4
GROUP BY ch.c_custkey, ch.c_name, ch.c_acctbal
HAVING SUM(od.total_price) > 5000
ORDER BY total_order_value DESC;
