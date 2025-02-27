WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            WHEN c.c_acctbal < 1000 THEN 'Low'
            ELSE 'High'
        END AS acctbal_category
    FROM 
        customer c
    WHERE 
        c.c_mktsegment IN ('FURNITURE', 'OFFICE')
), ExpensiveLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_extendedprice * (1 - l.l_discount) > 5000
)
SELECT 
    c.c_name,
    s.s_name,
    ps.ps_availqty,
    COALESCE(AVG(eli.net_price), 0) AS avg_expensive_item,
    CASE 
        WHEN COUNT(eli.l_orderkey) > 0 THEN 'Has High Value Orders'
        ELSE 'No High Value Orders'
    END AS order_status
FROM 
    FilteredCustomers c
LEFT JOIN 
    RankedSuppliers s ON c.c_nationkey = s.s_nationkey AND s.rank = 1
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    ExpensiveLineItems eli ON eli.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
GROUP BY 
    c.c_name, s.s_name, ps.ps_availqty
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0 OR ps.ps_availqty IS NULL
ORDER BY 
    c.c_name DESC, avg_expensive_item ASC;
