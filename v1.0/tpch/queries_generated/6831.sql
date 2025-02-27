WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    co.c_name, 
    co.total_sales, 
    ts.s_name AS top_supplier, 
    ts.total_supplycost
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.total_sales > 10000
JOIN 
    TopSuppliers ts ON ts.total_supplycost = (SELECT MAX(total_supplycost) FROM TopSuppliers)
WHERE 
    rp.rnk = 1
ORDER BY 
    co.total_sales DESC, 
    rp.p_name;
