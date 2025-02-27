WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        p.p_name,
        PRANK() OVER (PARTITION BY p.p_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_name,
        rs.p_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
SupplierDetails AS (
    SELECT 
        fs.s_name,
        fs.p_name,
        c.c_name,
        co.order_count,
        co.total_spent
    FROM 
        FilteredSuppliers fs
    JOIN 
        CustomerOrders co ON fs.s_name LIKE '%' || co.c_name || '%'
)
SELECT 
    sd.s_name,
    sd.p_name,
    sd.c_name,
    sd.order_count,
    sd.total_spent
FROM 
    SupplierDetails sd
WHERE 
    sd.total_spent > 1000
ORDER BY 
    sd.total_spent DESC;
