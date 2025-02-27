WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(c.c_acctbal) AS avg_customer_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.n_name,
    ns.supplier_count,
    ns.avg_customer_balance,
    rv.total_supply_value,
    od.order_total_value,
    CASE 
        WHEN od.order_total_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM RankedSuppliers rs
FULL OUTER JOIN NationSummary ns ON ns.n_nationkey = rs.s_suppkey
FULL OUTER JOIN HighValueParts rv ON rv.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost IS NOT NULL 
        AND ps.ps_availqty <> 0
    )
FULL OUTER JOIN OrdersWithDetails od ON od.o_orderkey = rs.s_suppkey
JOIN region r ON r.r_regionkey = ns.n_nationkey % 5
WHERE ns.avg_customer_balance IS NOT NULL 
AND (rs.s_acctbal > 1000 OR rv.total_supply_value < 100000)
ORDER BY r.r_name, ns.n_name

