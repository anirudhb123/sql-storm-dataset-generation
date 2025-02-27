WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rnk
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM orders o
    WHERE o.o_orderstatus = 'O'
      AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING COUNT(l.l_linenumber) > 5
)
SELECT 
    r.r_name,
    SUM(hv.total_revenue) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(MAX(rs.max_supplycost), 0) AS highest_supply_cost,
    STRING_AGG(DISTINCT c.c_name, ', ' ORDER BY c.c_name) AS customers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN RecentOrders o ON s.s_suppkey = o.o_orderkey
LEFT JOIN HighValueCustomers c ON o.o_orderkey = c.c_custkey
LEFT JOIN HighValueLineItems hv ON o.o_orderkey = hv.l_orderkey
WHERE r.r_name NOT LIKE '%bad%'
  AND (rs.max_supplycost IS NOT NULL OR s.s_name IS NOT NULL)
GROUP BY r.r_name
HAVING SUM(hv.total_revenue) > 10000
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 5;
