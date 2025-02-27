WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        0 AS level,
        s.s_acctbal,
        NULL AS parent_key
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        sh.level + 1,
        s.s_acctbal,
        sh.s_suppkey AS parent_key
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE 
        s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        sh.s_suppkey,
        sh.s_name,
        sh.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.s_acctbal DESC) AS ranking
    FROM 
        SupplierHierarchy sh
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    hvs.s_name AS top_supplier,
    hvs.s_acctbal AS supplier_balance
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem li ON co.c_custkey = li.l_orderkey
LEFT JOIN 
    HighValueSuppliers hvs ON li.l_suppkey = hvs.s_suppkey
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders) 
    AND hvs.ranking = 1
ORDER BY 
    co.total_spent DESC NULLS LAST;

