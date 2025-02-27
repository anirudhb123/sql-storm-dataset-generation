WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FinalSelection AS (
    SELECT rs.s_suppkey, rs.s_name, rs.s_acctbal, 
           hvp.p_partkey, hvp.p_name, 
           CONCAT('Supplier: ', rs.s_name, ' with Account Balance: ', CAST(rs.s_acctbal AS VARCHAR), 
                  ' supplies Part: ', hvp.p_name, 
                  ' with Total Supply Cost: ', CAST(hvp.total_supply_cost AS VARCHAR)) AS description
    FROM RankedSuppliers rs
    JOIN HighValueParts hvp ON rs.rn = 1
)
SELECT description
FROM FinalSelection
WHERE s_acctbal > 5000
ORDER BY s_acctbal DESC;
