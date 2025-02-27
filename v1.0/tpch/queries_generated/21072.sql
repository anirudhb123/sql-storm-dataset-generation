WITH RECURSIVE NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
TopSuppliers AS (
    SELECT n.n_name, ns.s_suppkey, ns.s_name, ns.s_acctbal
    FROM NationSupplier ns
    JOIN nation n ON n.n_nationkey = ns.n_nationkey
    WHERE ns.rn <= 3
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           COUNT(DISTINCT ps.ps_suppkey) AS unique_supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name,
    ps.total_avail_qty,
    ps.unique_supplier_count,
    CASE 
        WHEN ps.total_avail_qty IS NULL THEN 'Unavailable' 
        ELSE 'Available' 
    END AS availability_status,
    COUNT(l.l_orderkey) AS order_count,
    AVG(l.l_extendedprice) FILTER (WHERE l.l_discount > 0) AS avg_discounted_price,
    STRING_AGG(DISTINCT CONCAT(DATE_PART('year', l.l_shipdate), '-', l.l_shipmode), ', ') AS ship_dates
FROM PartSummary ps
FULL OUTER JOIN lineitem l ON ps.p_partkey = l.l_partkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
GROUP BY ps.p_partkey, ps.p_name, ts.s_name
HAVING COUNT(l.l_orderkey) > (
    SELECT AVG(order_count) 
    FROM (
        SELECT COUNT(o.o_orderkey) AS order_count 
        FROM orders o 
        WHERE o.o_orderstatus = 'F' 
        GROUP BY o.o_custkey
    ) AS order_summary
) 
ORDER BY ps.total_avail_qty DESC, ps.p_name ASC;
