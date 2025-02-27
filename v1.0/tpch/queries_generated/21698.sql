WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), 
HighValueSuppliers AS (
    SELECT 
        r.r_name, 
        n.n_name, 
        rs.s_suppkey, 
        rs.s_name 
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 3
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), 
FilteredOrderDetails AS (
    SELECT 
        od.o_orderkey, 
        od.o_orderdate,
        od.total_revenue,
        CASE 
            WHEN od.total_revenue IS NULL THEN 0 
            ELSE od.total_revenue 
        END AS adjusted_revenue
    FROM OrderDetails od
    WHERE od.o_orderdate >= DATE '2023-01-01'
)
SELECT 
    hvs.r_name AS region,
    hvs.n_name AS nation,
    hvs.s_name AS supplier_name,
    fo.o_orderkey,
    fo.o_orderdate,
    fo.adjusted_revenue,
    COALESCE(reinterpret.bizarre_expression, 'NULL_VALUE') AS bizarre_output
FROM HighValueSuppliers hvs
LEFT JOIN FilteredOrderDetails fo ON fo.o_orderkey IN (
    SELECT DISTINCT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal > ALL (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_nationkey = hvs.s_nationkey
        )
    )
)
FULL OUTER JOIN (
    SELECT 
        NULLIF(SUM(l_discount), 0) AS bizarre_expression 
    FROM lineitem 
    WHERE l_returnflag = 'R'
) AS reinterpret ON reinterpret.bizarre_expression IS NOT NULL
ORDER BY hvs.r_name, hvs.n_name, fo.o_orderdate DESC;
