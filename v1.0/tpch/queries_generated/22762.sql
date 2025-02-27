WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        p.p_brand, 
        p.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    r.r_name,
    COALESCE(hvc.total_spent, 0) AS total_spent,
    s.s_name,
    SUM(spi.ps_availqty) AS total_available_qty,
    AVG(spi.p_retailprice) AS average_price,
    COUNT(DISTINCT spi.ps_partkey) AS unique_parts_supplied
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank <= 3
LEFT JOIN 
    SupplierPartInfo spi ON s.s_suppkey = spi.ps_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON s.s_name LIKE CONCAT('%', hvc.c_name, '%')
WHERE 
    (hvc.total_spent IS NULL OR hvc.total_spent <= 500) 
    AND (s.s_acctbal IS NOT NULL OR hvc.c_custkey IS NULL)
GROUP BY 
    r.r_name, hvc.total_spent, s.s_name
HAVING 
    total_available_qty > 100
ORDER BY 
    r.r_name, total_spent DESC, s.s_name;
