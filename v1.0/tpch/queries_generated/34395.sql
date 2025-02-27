WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, os.total_spent, os.order_count,
           RANK() OVER (ORDER BY os.total_spent DESC) AS rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE os.total_spent > 1000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
SupplierOrderDetails AS (
    SELECT 
        s.s_suppkey, s.s_name, SUM(l.l_quantity) AS total_quantity, 
        SUM(l.l_extendedprice) AS total_value,
        NVL(de.(total_available), 0) AS availability
    FROM supplier s
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN PartDetails de ON l.l_partkey = de.p_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    cust.c_name AS customer_name, 
    supp.s_name AS supplier_name,
    os.total_spent AS total_customer_spent,
    so.total_value AS supplier_total_value,
    ph.level AS supplier_level
FROM TopCustomers cust
JOIN SupplierOrderDetails so ON so.total_quantity > 50
JOIN SupplierHierarchy ph ON so.s_suppkey = ph.s_suppkey
LEFT JOIN part p ON so.total_value > p.p_retailprice
WHERE p.p_container IS NULL OR p.p_container <> 'BOX'
ORDER BY total_customer_spent DESC, supplier_total_value ASC
FETCH FIRST 100 ROWS ONLY;
