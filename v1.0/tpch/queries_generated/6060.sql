WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost
    FROM 
        RankedSuppliers s
    JOIN 
        part p ON s.p_partkey = p.p_partkey
    JOIN 
        partsupp ps ON s.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.rn = 1
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
) 
SELECT 
    co.c_name, 
    co.o_orderkey, 
    co.total_revenue, 
    ts.s_name AS supplier_name, 
    ts.ps_supplycost 
FROM 
    CustomerOrders co
JOIN 
    TopSuppliers ts ON co.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
ORDER BY 
    co.total_revenue DESC, 
    ts.ps_supplycost ASC 
LIMIT 100;
