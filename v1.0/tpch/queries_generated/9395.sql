WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
)
SELECT 
    h.c_custkey,
    h.c_name,
    h.total_spent,
    t.s_name AS top_supplier,
    t.s_acctbal AS supplier_acctbal,
    t.p_name AS part_name
FROM 
    HighSpendingCustomers h
JOIN 
    TopSuppliers t ON h.c_custkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = t.p_partkey LIMIT 1)
WHERE 
    h.rank <= 10
ORDER BY 
    h.total_spent DESC, t.s_acctbal DESC;
