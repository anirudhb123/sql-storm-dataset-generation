WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(rs.TotalSupplyCost, 0) AS TotalSupplyCost,
    hvo.o_orderkey,
    hvo.c_name AS CustomerName,
    hvo.o_totalprice
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.SupplierRank = 1
FULL OUTER JOIN 
    HighValueOrders hvo ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey LIMIT 1)
WHERE 
    (p.p_size BETWEEN 10 AND 20 OR p.p_container IS NULL)
ORDER BY 
    p.p_partkey, hvo.o_totalprice DESC;
