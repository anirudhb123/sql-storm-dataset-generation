WITH RECURSIVE RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderSums AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_custkey
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, os.total_spent
    FROM customer c
    JOIN OrderSums os ON c.c_custkey = os.o_custkey
    WHERE os.total_spent > 100000
),
SupplierPartStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, sps.total_avail_qty, sps.avg_supply_cost
    FROM part p
    JOIN SupplierPartStats sps ON p.p_partkey = sps.ps_partkey
    WHERE sps.total_avail_qty > 500
)
SELECT r.r_name, COUNT(DISTINCT h.c_custkey) AS high_spending_count, 
       AVG(t.p_retailprice) AS avg_retail_price,
       COUNT(DISTINCT t.p_partkey) AS total_parts_available,
       COUNT(DISTINCT rs.s_suppkey) AS distinct_suppliers
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN HighSpendingCustomers h ON h.o_custkey = n.n_nationkey
LEFT JOIN TopParts t ON t.p_mfgr LIKE 'Manufacturer%'
LEFT JOIN RankedSuppliers rs ON rs.rank <= 5
GROUP BY r.r_name
HAVING COUNT(DISTINCT h.c_custkey) > 0
ORDER BY high_spending_count DESC, avg_retail_price DESC;
