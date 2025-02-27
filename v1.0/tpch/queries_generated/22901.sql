WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_availqty, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status
    FROM orders o
    WHERE YEAR(o.o_orderdate) = 2022
    AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31')
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers rs
    WHERE rs.rank = 1
),
TotalSales AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY l.l_partkey
)
SELECT 
    r.r_name, 
    n.n_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ts.total_revenue) AS yearly_revenue,
    SUM(CASE WHEN lo.o_orderkey IS NOT NULL THEN 1 ELSE 0 END) AS orders_completed
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN FilteredOrders lo ON c.c_custkey = lo.o_custkey
JOIN TotalSales ts ON ts.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM TopSuppliers s))
GROUP BY r.r_name, n.n_name
HAVING SUM(ts.total_revenue) IS NOT NULL 
   AND COUNT(DISTINCT c.c_custkey) > 0
ORDER BY yearly_revenue DESC, customer_count DESC
LIMIT 10;
