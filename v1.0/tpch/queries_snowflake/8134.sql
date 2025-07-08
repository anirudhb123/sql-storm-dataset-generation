WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), TopSuppliers AS (
    SELECT n.n_name, rs.s_suppkey, rs.s_name, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.rank <= 3
)
SELECT n.r_name, ts.n_name, COUNT(ts.s_suppkey) AS num_top_suppliers, 
       AVG(ts.total_supply_cost) AS avg_top_supply_cost
FROM TopSuppliers ts
JOIN region n ON n.r_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = ts.n_name)
GROUP BY n.r_name, ts.n_name
HAVING COUNT(ts.s_suppkey) > 1
ORDER BY n.r_name, avg_top_supply_cost DESC;
