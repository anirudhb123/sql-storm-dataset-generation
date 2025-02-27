WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT co.o_orderkey) AS order_count, 
    SUM(co.revenue) AS total_revenue, 
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM RankedSuppliers rs
JOIN nation n ON rs.n_regionkey = n.n_nationkey
JOIN CustomerOrders co ON co.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = n.n_nationkey
)
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rs.rank <= 5
GROUP BY r.r_name
ORDER BY total_revenue DESC;
