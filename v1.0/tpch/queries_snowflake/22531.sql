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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders) 
), 
FrequentOrderers AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(rs.s_acctbal, 0) AS supplier_account_balance,
    hvc.total_spent AS customer_spending,
    fo.order_count AS customer_order_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    FrequentOrderers fo ON fo.o_custkey = (SELECT MIN(o_custkey) FROM orders WHERE o_orderkey = ps.ps_suppkey)
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = fo.o_custkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size <> p.p_size
    ) 
    AND (rs.s_acctbal IS NULL OR rs.s_acctbal > 1000)
ORDER BY 
    p.p_partkey DESC NULLS LAST;
