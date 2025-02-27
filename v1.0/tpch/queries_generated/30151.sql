WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, SUM(ps.ps_availqty) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
),
MinMaxSuppliers AS (
    SELECT MIN(s.s_acctbal) AS min_balance, MAX(s.s_acctbal) AS max_balance
    FROM supplier s
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    AND o.o_totalprice > (SELECT avg(o_totalprice) FROM orders WHERE o_orderdate < '2023-01-01')
)
SELECT 
    r.n_name,
    p.p_name,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_sales,
    MIN(mm.min_balance) AS min_supplier_balance,
    MAX(mm.max_balance) AS max_supplier_balance,
    COUNT(DISTINCT tc.c_custkey) AS active_customers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem li ON li.l_partkey = p.p_partkey
JOIN RankedLineItems rli ON li.l_orderkey = rli.l_orderkey
JOIN FilteredOrders fo ON li.l_orderkey = fo.o_orderkey
JOIN TopCustomers tc ON tc.c_custkey = fo.o_custkey
CROSS JOIN MinMaxSuppliers mm
WHERE p.p_retailprice > 50
GROUP BY r.n_name, p.p_name
ORDER BY total_sales DESC, r.n_name, p.p_name
WITH ROLLUP;
