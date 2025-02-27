WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
            WHERE c2.c_nationkey = c.c_nationkey
        )
    )
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierStatistics AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RegionRevenue AS (
    SELECT r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY r.r_name
)
SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, 
       COALESCE(rs.total_revenue, 0) AS revenue, 
       ss.part_count, ss.total_supply_value
FROM OrderHierarchy oh
LEFT JOIN RegionRevenue rs ON rs.total_revenue > 5000
JOIN SupplierStatistics ss ON ss.part_count > 10
WHERE oh.o_totalprice > (SELECT AVG(o2.o_totalprice) 
                          FROM orders o2 
                          WHERE o2.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31')
ORDER BY oh.o_orderdate DESC, oh.o_totalprice DESC;
