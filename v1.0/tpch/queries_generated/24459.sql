WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        CAST(c.c_name AS VARCHAR(100)) AS full_name,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) * 0.5 FROM customer c2)
    
    UNION ALL
    
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        CONCAT(ch.full_name, ' | ', c.c_name), 
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ch.c_custkey % 25)
    WHERE 
        ch.level < 5
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT * 
    FROM SupplierStats 
    WHERE rn <= 3
)
SELECT 
    ch.full_name,
    ts.s_name,
    ts.total_supply_cost,
    CASE 
        WHEN ch.c_acctbal IS NULL THEN 'No balance'
        ELSE CAST(ROUND(ch.c_acctbal / NULLIF(ts.total_supply_cost, 0) * 100, 2) AS VARCHAR(10)) || '%'
    END AS acctbal_percentage,
    ts.s_name || ' | ' || (SELECT COUNT(DISTINCT o.o_orderkey) FROM orders o WHERE o.o_custkey = ch.c_custkey AND o.o_orderstatus = 'O') AS order_summary
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    TopSuppliers ts ON ch.c_custkey % 100 = ts.s_suppkey
ORDER BY 
    acctbal_percentage DESC NULLS LAST, 
    ch.level DESC, 
    ch.full_name;
