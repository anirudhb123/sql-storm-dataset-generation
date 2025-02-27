WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rk
    FROM supplier s
),
HighValueParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 500 AND o.o_orderdate >= '2023-01-01'
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity,
           (l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) AS net_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
)
SELECT 
    c.c_name,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    p.p_name,
    SUM(f.net_price) AS total_net_price,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(f.net_price) DESC) AS customer_rank
FROM CustomerOrders c
LEFT JOIN lineitem l ON c.o_orderkey = l.l_orderkey
LEFT JOIN HighValueParts hp ON l.l_partkey = hp.ps_partkey
LEFT JOIN RankedSuppliers s ON s.s_nationkey = c.c_nationkey AND s.rk = 1
JOIN part p ON l.l_partkey = p.p_partkey
JOIN FilteredLineItems f ON l.l_orderkey = f.l_orderkey
WHERE p.p_retailprice < 50.00
GROUP BY c.c_custkey, c.c_name, supplier_name, p.p_name
ORDER BY total_net_price DESC;

