WITH HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
OrderPartStats AS (
    SELECT h.o_orderkey, pd.p_name, SUM(l.l_quantity) AS total_quantity, SUM(l.l_extendedprice) AS total_extended_price
    FROM HighValueOrders h
    JOIN lineitem l ON h.o_orderkey = l.l_orderkey
    JOIN PartDetails pd ON l.l_partkey = pd.p_partkey
    GROUP BY h.o_orderkey, pd.p_name
)
SELECT 
    o.o_orderkey,
    SUM(ops.total_quantity) AS total_quantity,
    SUM(ops.total_extended_price) AS total_revenue,
    si.supplier_nation,
    COUNT(DISTINCT ops.p_name) AS unique_parts_count
FROM HighValueOrders o
JOIN OrderPartStats ops ON o.o_orderkey = ops.o_orderkey
JOIN SupplierInfo si ON ops.p_name LIKE CONCAT('%', si.s_suppkey, '%')
GROUP BY o.o_orderkey, si.supplier_nation
ORDER BY total_revenue DESC
LIMIT 10;
