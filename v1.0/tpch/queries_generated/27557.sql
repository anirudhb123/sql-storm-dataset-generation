WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, p.p_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) FROM customer c2
        )
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    r.s_name,
    r.p_name,
    r.TotalCost,
    h.c_name AS HighValueCustomer,
    h.OrderCount
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers h ON r.TotalCost > (
        SELECT AVG(TotalCost) FROM RankedSuppliers
    )
WHERE 
    r.Rank = 1
ORDER BY 
    r.TotalCost DESC, h.OrderCount DESC;
