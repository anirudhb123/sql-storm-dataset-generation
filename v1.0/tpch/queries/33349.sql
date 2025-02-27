
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CAST(NULL AS integer) AS parent_suppkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey AS parent_suppkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.parent_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
NationSupplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
AveragePrice AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_discount,
        ROW_NUMBER() OVER (PARTITION BY li.l_orderkey ORDER BY li.l_extendedprice DESC) AS row_num
    FROM lineitem li
    WHERE li.l_shipdate >= '1997-01-01' AND li.l_shipdate < '1998-01-01'
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    AVG(ap.avg_supply_cost) AS average_supply_cost,
    SUM(co.total_spent) AS total_spent_per_nation,
    SUM(CASE WHEN fli.row_num = 1 THEN fli.l_quantity * (1 - fli.l_discount) END) AS top_order_amount
FROM NationSupplier ns
JOIN AveragePrice ap ON ns.supplier_count > 5
JOIN CustomerOrderStats co ON ns.supplier_count = co.total_orders
LEFT JOIN FilteredLineItems fli ON fli.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Corp%')
)
GROUP BY ns.n_name, ns.supplier_count
HAVING AVG(ap.avg_supply_cost) > 200
ORDER BY total_spent_per_nation DESC;
