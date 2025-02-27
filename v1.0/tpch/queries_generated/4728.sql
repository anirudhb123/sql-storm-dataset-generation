WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(COALESCE(o.o_totalprice, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
SalesData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    c.c_name AS customer_name,
    COALESCE(SUM(sd.total_value), 0) AS total_sales,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    SalesData sd ON co.c_custkey IS NULL OR sd.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
WHERE 
    co.total_spent IS NOT NULL
GROUP BY 
    r.r_name, c.c_name
ORDER BY 
    total_sales DESC, supplier_count ASC;
