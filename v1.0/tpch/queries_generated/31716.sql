WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
SupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           AVG(p.p_retailprice) AS avg_retail_price,
           COUNT(*) AS total_supply
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    c.c_name,
    o.o_orderkey,
    COALESCE(SUM(CASE WHEN li.l_linestatus = 'F' THEN li.l_extendedprice END), 0) AS sold_price,
    COALESCE(SUM(CASE WHEN li.l_linestatus = 'O' THEN li.l_extendedprice END), 0) AS open_price,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE s.s_acctbal > 50000) AS high_balance_suppliers,
    s.s_name,
    ts.total_supply_cost
FROM CustomerOrders o
LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN supplier s ON li.l_suppkey = s.s_suppkey
LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
GROUP BY c.c_name, o.o_orderkey, s.s_name, ts.total_supply_cost
HAVING COUNT(li.l_orderkey) >= 2 AND SUM(li.l_tax) < 1000
ORDER BY sold_price DESC, open_price DESC;
