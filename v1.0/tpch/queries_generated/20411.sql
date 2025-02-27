WITH RecursivePartSupp AS (
    SELECT ps.partkey, ps.suppkey, ps.availqty, ps.supplycost, 0 AS level
    FROM partsupp ps
    WHERE ps.availqty < 50
    UNION ALL
    SELECT p.ps_partkey, p.ps_suppkey, CASE 
        WHEN p.ps_availqty IS NULL THEN 0 
        ELSE p.ps_availqty + 100 
    END, p.ps_supplycost, level + 1
    FROM partsupp p
    JOIN RecursivePartSupp r ON p.ps_suppkey = r.suppkey
    WHERE level < 3
),
TopSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN RecursivePartSupp ps ON s.s_suppkey = ps.suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps ps_supplycost)
                                     FROM partsupp ps)
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
RegionSales AS (
    SELECT r.r_regionkey, SUM(os.total_price) AS region_total_sales
    FROM region r
    LEFT JOIN OrderSummary os ON r.r_regionkey = (SELECT n.n_regionkey 
                                                   FROM nation n 
                                                   JOIN customer c ON n.n_nationkey = c.c_nationkey 
                                                   WHERE c.c_custkey = os.o_orderkey)
    GROUP BY r.r_regionkey
    HAVING region_total_sales IS NOT NULL
)
SELECT r.r_name, rs.region_total_sales, ts.total_supply_cost 
FROM RegionSales rs
JOIN region r ON rs.r_regionkey = r.r_regionkey
LEFT JOIN TopSuppliers ts ON ts.total_supply_cost = (
    SELECT MAX(total_supply_cost) FROM TopSuppliers
)
WHERE r.r_name NOT LIKE '%(X)%'
ORDER BY rs.region_total_sales DESC, r.r_name;
