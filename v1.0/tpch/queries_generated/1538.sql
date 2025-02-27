WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        l.l_returnflag,
        l.l_linestatus
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY l.l_orderkey, l.l_returnflag, l.l_linestatus
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    SUM(CASE WHEN fi.l_returnflag = 'R' THEN fi.net_revenue ELSE 0 END) AS returned_revenue,
    SUM(fi.net_revenue) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS top_suppliers_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN CustomerOrderStats co ON co.c_custkey = s.s_suppkey
LEFT JOIN FilteredLineItems fi ON fi.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE rs.rn <= 3
GROUP BY r.r_name
ORDER BY total_revenue DESC, unique_customers DESC;
