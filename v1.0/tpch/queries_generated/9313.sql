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
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_type
    FROM 
        RankedSuppliers s
    JOIN 
        part p ON s.p_type = p.p_type
    WHERE 
        rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(t.total_spent) AS customer_total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(ts.s_acctbal) AS supplier_acct_total
    FROM 
        CustomerOrders c
    LEFT JOIN 
        TopSuppliers ts ON c.c_custkey = ts.s_suppkey
    LEFT JOIN 
        orders o ON c.o_orderkey = o.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.customer_total_spent,
    fr.order_count,
    fr.supplier_acct_total
FROM 
    FinalReport fr
WHERE 
    fr.customer_total_spent > 10000
ORDER BY 
    fr.customer_total_spent DESC;
