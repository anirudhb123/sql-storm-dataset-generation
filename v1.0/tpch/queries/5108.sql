WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal, 
        rs.nation_name
    FROM RankedSuppliers rs
    WHERE rs.rank <= 5
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY total_quantity DESC
    LIMIT 10
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name AS customer_name, 
        ps.ps_supplycost, 
        pp.p_name AS part_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN part pp ON ps.ps_partkey = pp.p_partkey
    WHERE pp.p_partkey IN (SELECT p_partkey FROM PopularParts)
) 
SELECT 
    od.o_orderkey, 
    od.o_orderdate, 
    od.customer_name, 
    SUM(od.ps_supplycost * od.o_totalprice) AS total_cost,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT ts.s_name, ', ') AS supplier_names
FROM OrderDetails od
JOIN TopSuppliers ts ON od.ps_supplycost < ts.s_acctbal
GROUP BY od.o_orderkey, od.o_orderdate, od.customer_name
ORDER BY total_cost DESC
LIMIT 20;
