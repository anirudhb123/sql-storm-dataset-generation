WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_custkey,
        CASE 
            WHEN (o.o_totalprice > 1000) THEN 'High Value'
            WHEN (o.o_totalprice BETWEEN 500 AND 1000) THEN 'Medium Value'
            ELSE 'Low Value'
        END AS order_value_category
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierBalance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal < 1000 THEN 'Low Balance' 
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance'
        END AS balance_category
    FROM 
        supplier s
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.order_value_category,
    ps.total_cost,
    s.s_name, 
    sb.balance_category,
    COALESCE(sb.s_name, 'Unknown Supplier') AS supplier_result
FROM 
    QualifiedOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers ps ON l.l_suppkey = ps.s_suppkey AND ps.rank_within_nation = 1
JOIN 
    customer c ON o.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierBalance sb ON ps.s_suppkey = sb.s_suppkey
WHERE 
    NOT EXISTS (SELECT 1 FROM orders o2 WHERE o2.o_custkey = o.o_custkey AND o2.o_orderkey < o.o_orderkey)
ORDER BY 
    o.o_orderdate DESC, total_cost DESC;
