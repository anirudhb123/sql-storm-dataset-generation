
WITH SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT sp.s_suppkey, sp.s_name, sp.ps_partkey, sp.p_name, sp.ps_supplycost, sp.ps_availqty
    FROM SupplierPart sp
    WHERE sp.rn <= 3 
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT rs.r_name,
       COALESCE(SUM(ts.ps_supplycost), 0) AS total_supply_cost,
       COALESCE(SUM(co.total_spent), 0) AS total_spent_by_customers,
       CASE 
           WHEN COUNT(DISTINCT ts.s_suppkey) > 0 THEN 'Available'
           ELSE 'Unavailable'
       END AS supply_status
FROM RegionSummary rs
LEFT JOIN TopSuppliers ts ON ts.s_name LIKE '%' || rs.r_name || '%'
LEFT JOIN CustomerOrder co ON co.c_custkey IN (
    SELECT DISTINCT c.c_custkey 
    FROM customer c 
    WHERE c.c_address LIKE '%' || rs.r_name || '%'
)
WHERE rs.nation_count > 0
GROUP BY rs.r_name
ORDER BY rs.r_name;
