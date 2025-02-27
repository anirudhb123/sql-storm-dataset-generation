WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
        AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
),
Selection AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        p.p_retailprice > 100.00
        AND l.l_returnflag = 'N'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    s.s_name,
    s.total_supply_value,
    cnt.order_count,
    cnt.revenue,
    c.c_name AS high_value_customer_name
FROM 
    RankedSuppliers s
LEFT JOIN 
    Selection cnt ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM Selection p) LIMIT 1)
JOIN 
    HighValueCustomers c ON c.customer_rank <= 10
WHERE 
    (s.total_supply_value IS NOT NULL AND s.total_supply_value > 10000.00)
    OR (s.s_acctbal IS NULL AND s.s_name LIKE '%Supplier%')
ORDER BY 
    s.total_supply_value DESC, c.c_acctbal DESC;
