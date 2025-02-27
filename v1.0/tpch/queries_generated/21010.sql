WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate < CURRENT_DATE
        )
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS PartsSupplied
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS OrdersCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS TotalAvailable
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice < (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    rs.o_orderkey,
    rs.o_orderdate,
    cs.TotalSpent,
    ps.p_name,
    ps.TotalAvailable,
    sd.PartsSupplied,
    RANK() OVER (PARTITION BY cs.c_custkey ORDER BY cs.TotalSpent DESC) AS CustomerRank
FROM 
    RankedOrders rs
JOIN 
    CustomerStats cs ON rs.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN 
    FilteredParts ps ON ps.TotalAvailable > 10 
LEFT JOIN 
    SupplierDetails sd ON sd.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    cs.TotalSpent IS NOT NULL 
    AND sd.PartsSupplied > 0 
    AND (rs.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' OR rs.o_orderdate IS NULL)
ORDER BY 
    rs.o_orderdate DESC, cs.TotalSpent DESC;
