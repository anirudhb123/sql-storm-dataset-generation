WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 as Level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.Level + 1
    FROM CustomerOrders co
    JOIN orders o ON co.o_orderkey < o.o_orderkey
    WHERE co.Level < 5
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name, s.s_acctbal
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, l.l_returnflag
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY l.l_orderkey, l.l_returnflag
)
SELECT co.c_name,
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(fl.revenue) AS total_revenue,
       COUNT(sp.ps_partkey) AS total_parts,
       AVG(sp.s_acctbal) AS avg_supplier_balance
FROM CustomerOrders co
LEFT JOIN FilteredLineItems fl ON co.o_orderkey = fl.l_orderkey
LEFT JOIN SupplierParts sp ON fl.l_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey IN (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.ps_suppkey))
GROUP BY co.c_custkey, co.c_name
HAVING SUM(fl.revenue) > 10000
ORDER BY total_orders DESC, total_revenue DESC
LIMIT 100;
