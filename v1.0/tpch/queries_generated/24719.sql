WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS Level 
    FROM customer c 
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.Level + 1
    FROM customer c 
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
    WHERE ch.Level < 5 AND c.c_acctbal > ch.c_acctbal
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) BETWEEN 10000 AND 50000
),
OrderStats AS (
    SELECT o.o_orderkey, 
           COUNT(DISTINCT l.l_orderkey) AS LineItemCount,
           SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS NetRevenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE YEAR(o.o_orderdate) = 2023
    GROUP BY o.o_orderkey
)
SELECT 
    ch.c_name AS CustomerName,
    s.s_name AS SupplierName,
    os.lineitemcount,
    os.netrevenue,
    rh.r_name AS RegionName,
    CASE 
        WHEN os.netrevenue IS NULL THEN 'No Revenue'
        WHEN os.netrevenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS RevenueCategory
FROM CustomerHierarchy ch
JOIN TopSuppliers ts ON ch.c_custkey = ts.ps_suppkey
JOIN OrderStats os ON ts.ps_suppkey = os.o_orderkey
JOIN supplier s ON ts.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region rh ON n.n_regionkey = rh.r_regionkey
WHERE ch.Level <= (SELECT MAX(Level) FROM CustomerHierarchy)
AND (s.s_acctbal IS NOT NULL OR os.LineItemCount > 0)
ORDER BY RevenueCategory DESC, os.NetRevenue DESC;
