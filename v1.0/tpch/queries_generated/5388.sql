WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 5
),
OrderAggregates AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name,
    c.c_address,
    c.c_phone,
    o.total_spent,
    o.order_count,
    COALESCE(s.s_name, 'No supplier') AS top_supplier
FROM 
    customer c
LEFT JOIN 
    OrderAggregates o ON c.c_custkey = o.c_custkey
LEFT JOIN 
    TopSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type IN (SELECT DISTINCT p_type FROM part)))
WHERE 
    o.total_spent > 5000
ORDER BY 
    total_spent DESC;
