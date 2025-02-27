WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey,
           1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 10000 AND ch.level < 5
),
TotalPrices AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
SuppliersInfo AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_name, s.s_acctbal, si.total_avail_qty, si.avg_supply_cost
    FROM supplier s
    JOIN SuppliersInfo si ON s.s_suppkey = si.s_suppkey
    WHERE si.rank <= 5
)
SELECT 
    ch.c_name AS customer_name, 
    ch.c_acctbal AS customer_balance, 
    tp.total_price AS order_total,
    ts.s_name AS supplier_name,
    ts.total_avail_qty,
    ts.avg_supply_cost,
    CASE 
        WHEN ts.avg_supply_cost IS NULL THEN 'NO SUPPLIERS'
        ELSE 'HAS SUPPLIERS'
    END AS supplier_status
FROM CustomerHierarchy ch
LEFT JOIN TotalPrices tp ON ch.c_custkey = tp.o_orderkey
LEFT JOIN TopSuppliers ts ON tp.total_price > ts.avg_supply_cost
ORDER BY ch.c_acctbal DESC, tp.total_price DESC;
