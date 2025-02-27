WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalSupplyCost DESC
    LIMIT 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING TotalOrderValue > 100000
),
NationDetails AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT c.c_custkey) AS CustomerCount
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    td.nation_name, 
    td.region_name, 
    ts.s_name AS supplier_name, 
    ts.TotalSupplyCost, 
    ho.TotalOrderValue, 
    ho.o_orderkey
FROM 
    NationDetails td
JOIN 
    TopSuppliers ts ON ts.TotalSupplyCost > 1000000
JOIN 
    HighValueOrders ho ON ho.TotalOrderValue > 150000
ORDER BY 
    TotalSupplyCost DESC, 
    TotalOrderValue DESC;
