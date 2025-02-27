WITH RECURSIVE PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 1 AS recursion_level
    FROM partsupp ps
    WHERE ps.ps_availqty > 100
    UNION ALL
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, recursion_level + 1
    FROM partsupp ps
    INNER JOIN PartSupplier ps_up ON ps.ps_partkey = ps_up.ps_partkey
    WHERE ps.ps_availqty > ps_up.ps_availqty
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY total_sales DESC
    LIMIT 5
)
SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, tr.r_name, tr.total_sales
FROM PartSupplier ps
JOIN TopRegions tr ON ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l 
                                          JOIN orders o ON l.l_orderkey = o.o_orderkey
                                          WHERE o.o_totalprice > 5000)
ORDER BY ps.ps_supplycost DESC, ps.ps_availqty ASC;
