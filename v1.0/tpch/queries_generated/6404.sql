WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nation_name
    FROM RankedSuppliers s
    WHERE s.rank_by_acctbal <= 5
),
OrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierOrderDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, ps.ps_supplycost, 
           s.s_suppkey, s.s_name
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN TopSuppliers s ON ps.ps_suppkey = s.s_suppkey
)
SELECT o.cust_key, o.total_order_value, COUNT(DISTINCT sod.l_orderkey) AS unique_orders,
       SUM(sod.l_extendedprice) AS total_extended_price,
       SUM(sod.l_extendedprice - sod.ps_supplycost * sod.l_quantity) AS total_profit
FROM OrderSummary o
JOIN SupplierOrderDetails sod ON o.c_custkey = sod.l_orderkey
GROUP BY o.cust_key, o.total_order_value
HAVING total_profit > 10000
ORDER BY total_profit DESC;
