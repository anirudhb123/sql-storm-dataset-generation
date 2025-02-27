WITH RECURSIVE Customer_Filter AS (
    SELECT c_custkey, c_name, c_acctbal
    FROM customer
    WHERE c_acctbal > (
        SELECT AVG(c_acctbal) FROM customer
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    INNER JOIN Customer_Filter cf ON c.c_custkey = cf.c_custkey - 1
    WHERE c.c_acctbal > (
        SELECT AVG(c_acctbal) FROM customer
    )
),
Supplier_Stats AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
Order_Summary AS (
    SELECT o.o_orderkey,
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name,
    r.r_name,
    cf.c_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_revenue_generated,
    COALESCE(SUM(ss.total_available), 0) AS total_available_parts,
    COUNT(DISTINCT ss.s_suppkey) FILTER (WHERE ss.avg_supply_cost < (
        SELECT AVG(avg_supply_cost) FROM Supplier_Stats
    )) AS efficient_suppliers,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN Customer_Filter cf ON c.c_custkey = cf.c_custkey
LEFT JOIN Order_Summary os ON cf.c_custkey = os.o_orderkey
LEFT JOIN Supplier_Stats ss ON ss.total_available > (
    SELECT AVG(total_available) FROM Supplier_Stats
)
GROUP BY n.n_name, r.r_name, cf.c_name
HAVING COUNT(DISTINCT os.o_orderkey) > 2 AND SUM(os.total_revenue) IS NOT NULL
ORDER BY revenue_rank, n.n_name;
