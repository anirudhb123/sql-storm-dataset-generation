WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    co.order_count,
    co.total_spent,
    ps.total_available,
    s.s_name,
    s.rank_acctbal
FROM 
    CustomerOrders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT OUTER JOIN 
    PartDetails ps ON ps.total_available > 0
LEFT JOIN 
    RankedSuppliers s ON s.rank_acctbal <= 10
WHERE 
    c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
ORDER BY 
    co.total_spent DESC, rank_acctbal ASC;
