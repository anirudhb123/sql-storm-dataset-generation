WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS supplier_nation, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice,
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o1.o_totalprice) FROM orders o1)
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT r.s_name AS top_supplier, r.s_acctbal, p.p_name, p.total_available_qty, 
       p.avg_supply_cost, h.o_orderkey, h.line_item_count
FROM RankedSuppliers r
JOIN PartDetails p ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
                                       (SELECT p.p_partkey FROM part p WHERE p.p_brand LIKE 'Brand#%'))
JOIN HighValueOrders h ON h.line_item_count > 5
WHERE r.rank <= 3
ORDER BY r.s_acctbal DESC, p.p_retailprice DESC;
