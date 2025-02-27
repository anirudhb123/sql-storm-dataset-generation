WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_per_region
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c_inner.c_acctbal) FROM customer c_inner)
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(o.o_orderkey) > 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierOrders AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_from_supplier
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS high_value_customers,
    SUM(CASE WHEN os.total_revenue IS NULL THEN 0 ELSE os.total_revenue END) AS total_revenue,
    COUNT(DISTINCT ss.s_suppkey) AS high_value_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN HighValueCustomers c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderDetails os ON c.c_custkey = os.o_orderkey
LEFT JOIN (SELECT DISTINCT s_suppkey FROM RankedSuppliers WHERE rank_per_region <= 3) ss ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ss.s_suppkey)
GROUP BY r.r_name
HAVING SUM(CASE WHEN total_revenue IS NULL THEN 1 ELSE 0 END) < 5
ORDER BY r.r_name ASC;

