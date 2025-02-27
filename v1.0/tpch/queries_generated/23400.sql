WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank,
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
MaxAvailability AS (
    SELECT ps.partkey,
           MAX(total_avail_qty) AS max_avail_qty
    FROM RankedSuppliers
    WHERE rank = 1
    GROUP BY ps.partkey
),
OrderDetails AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(DISTINCT l.l_returnflag) AS unique_return_flags
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate <= DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
SupplierSummary AS (
    SELECT DISTINCT n.n_name AS nation_name,
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT p.p_partkey,
       p.p_name,
       s.s_name AS top_supplier,
       COALESCE(ma.max_avail_qty, 0) AS max_availability,
       COALESCE(ods.total_order_value, 0) AS total_value,
       ss.nation_name,
       ss.total_supply_cost,
       ss.supplier_count
FROM part p
LEFT JOIN RankedSuppliers s ON p.p_partkey = s.ps_partkey AND s.rank = 1
LEFT JOIN MaxAvailability ma ON p.p_partkey = ma.partkey
LEFT JOIN OrderDetails ods ON ods.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' LIMIT 1)
LEFT JOIN SupplierSummary ss ON ss.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = s.s_suppkey LIMIT 1))
WHERE p.p_container NOT LIKE '%BOX%'
  AND (p.p_retailprice IS NULL OR p.p_retailprice > 100.00)
ORDER BY p.p_partkey;
