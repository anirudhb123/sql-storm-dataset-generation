WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
), RegionCustomerCount AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    COALESCE(rc.customer_count, 0) AS customer_count,
    SUM(h.net_revenue) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')')) AS suppliers,
    AVG(su.s_acctbal) AS average_supplier_balance
FROM RegionCustomerCount rc
FULL OUTER JOIN RankedSuppliers s ON rc.r_name = (SELECT n.n_name 
                                                    FROM nation n 
                                                    WHERE s.s_nationkey = n.n_nationkey)
FULL OUTER JOIN HighValueOrders h ON h.o_orderkey IN (SELECT o.o_orderkey 
                                                         FROM orders o 
                                                         WHERE o.o_orderstatus = 'F')
LEFT JOIN supplier su ON s.s_suppkey = su.s_suppkey
GROUP BY r.r_name, rc.customer_count
HAVING total_revenue IS NOT NULL OR AVG(su.s_acctbal) > 1000
ORDER BY total_revenue DESC, r.r_name;
