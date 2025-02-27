WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name AS region_name,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, s.s_name AS supplier_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_type LIKE '%steel%'
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_orderkey) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING COUNT(l.l_orderkey) > 5
),
FinalResults AS (
    SELECT r.region_name, pd.supplier_name, 
           SUM(pd.ps_supplycost * pd.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT os.o_orderkey) AS order_count
    FROM RankedSuppliers r
    JOIN PartDetails pd ON r.s_suppkey = pd.supplier_name
    JOIN OrderStatistics os ON os.o_orderkey = pd.p_partkey
    WHERE r.rank <= 3
    GROUP BY r.region_name, pd.supplier_name
)
SELECT region_name, supplier_name, total_supply_cost, order_count
FROM FinalResults
ORDER BY region_name, total_supply_cost DESC;
