WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.rn = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.ps_partkey,
    r.ps_availqty,
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    od.total_price,
    od.part_count
FROM 
    TopSuppliers r
FULL OUTER JOIN 
    CustomerOrders co ON r.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = r.s_suppkey)
LEFT JOIN 
    OrderDetails od ON co.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
WHERE 
    (co.order_count > 10 OR r.ps_availqty < 50) 
    AND (r.ps_supplycost BETWEEN 10.00 AND 100.00 OR od.total_price IS NULL)
ORDER BY 
    r.ps_partkey, co.total_spent DESC;
