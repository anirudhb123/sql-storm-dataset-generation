WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM lineitem l
    GROUP BY l.l_orderkey
),
TopSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name
),
FinalSummary AS (
    SELECT co.c_custkey, co.c_name, tso.total_cost, lis.total_spent
    FROM CustomerOrders co
    LEFT JOIN LineItemSummary lis ON co.o_orderkey = lis.l_orderkey
    LEFT JOIN TopSuppliers tso ON co.o_orderkey = tso.s_suppkey
)
SELECT f.c_custkey, f.c_name, COALESCE(f.total_cost, 0) AS total_supplier_cost,
       COALESCE(f.total_spent, 0) AS total_customer_spent,
       (COALESCE(f.total_spent, 0) - COALESCE(f.total_cost, 0)) AS profit_loss
FROM FinalSummary f
ORDER BY profit_loss DESC
LIMIT 10;
