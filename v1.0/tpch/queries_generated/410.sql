WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0 AND s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500.00 OR c.c_name LIKE '%Corp%'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValuePart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' 
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
)
SELECT 
    c.c_name,
    c.total_spent,
    p.p_name,
    s.s_name,
    r.s_acctbal
FROM 
    CustomerOrders c
JOIN 
    HighValuePart p ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_custkey = c.c_custkey AND l.l_partkey = p.p_partkey
    )
LEFT JOIN 
    RankedSuppliers s ON p.p_partkey = s.s_suppkey AND s.rank = 1
WHERE 
    c.total_orders > 5 
    AND (c.total_spent IS NOT NULL AND c.total_spent < 200000)
ORDER BY 
    c.total_spent DESC, s.s_acctbal DESC
LIMIT 10;
