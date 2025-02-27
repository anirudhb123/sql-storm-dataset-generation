WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierNationStats AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    s.s_name AS supplier_name,
    cv.c_name AS customer_name,
    cv.total_spent,
    COALESCE(n.supplier_count, 0) AS supplier_count,
    COALESCE(n.total_account_balance, 0) AS total_account_balance
FROM 
    region r
LEFT JOIN 
    supplier s ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN 
    HighValueCustomers cv ON cv.c_custkey IN (
        SELECT o.o_custkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_discount > 0.1
    )
LEFT JOIN 
    SupplierNationStats n ON r.r_name = n.n_name
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank = 1
WHERE 
    s.s_acctbal IS NOT NULL AND cv.total_spent IS NOT NULL
ORDER BY 
    r.r_name, cv.total_spent DESC;
