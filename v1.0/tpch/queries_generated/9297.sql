WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.s_acctbal, rs.nation_name
    FROM RankedSuppliers rs
    WHERE rs.rank <= 3
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ts.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
)
SELECT p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost, 
       AVG(ts.s_acctbal) AS avg_supp_acctbal
FROM PartSupplierDetails ps
JOIN part p ON p.p_partkey = ps.p_partkey
GROUP BY p.p_name
HAVING SUM(ps.ps_availqty) > 1000
ORDER BY total_avail_qty DESC;
