WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        COUNT(ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, p.p_name
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
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey
)
SELECT 
    rs.s_name AS supplier_name,
    rs.s_acctbal AS supplier_account_balance,
    co.c_name AS customer_name,
    co.line_item_count AS order_line_item_count,
    CONCAT('Supplier: ', rs.s_name, ' | Customer: ', co.c_name) AS combined_info
FROM 
    TopSuppliers rs
JOIN 
    CustomerOrders co ON co.c_acctbal >= rs.s_acctbal
WHERE 
    co.line_item_count > 0
ORDER BY 
    rs.s_name, co.c_name;
