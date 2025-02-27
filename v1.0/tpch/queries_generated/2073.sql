WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier AS s
    JOIN nation AS n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
OrdersWithTotal AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders AS o
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
SuppliersPartInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp AS ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FinalSelection AS (
    SELECT p.p_name, p.p_brand, p.p_type, p.p_size,
           COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
           COALESCE(ORD.order_total, 0) AS total_order_value,
           S.total_avail_qty
    FROM part AS p
    LEFT JOIN RankedSuppliers AS RS ON RS.rn = 1
    LEFT JOIN SuppliersPartInfo AS S ON p.p_partkey = S.ps_partkey
    LEFT JOIN OrdersWithTotal AS ORD ON ORD.o_custkey = (
        SELECT o.o_custkey
        FROM orders o 
        WHERE o.o_orderkey IN (
            SELECT l.l_orderkey
            FROM lineitem l
            WHERE l.l_partkey = p.p_partkey
        )
        LIMIT 1
    )
    WHERE p.p_size > 10
      AND (p.p_comment NOT LIKE '%fragile%' OR p.p_comment IS NULL)
)
SELECT f.p_name, f.supplier_name, f.total_order_value, f.total_avail_qty
FROM FinalSelection AS f
WHERE f.total_avail_qty > (
    SELECT AVG(total_avail_qty)
    FROM SuppliersPartInfo
)
ORDER BY f.total_order_value DESC, f.p_name;
