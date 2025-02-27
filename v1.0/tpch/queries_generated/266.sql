WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
OrdersWithTotal AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(owt.total_amount), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        OrdersWithTotal owt ON c.c_custkey = owt.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    c.total_spent,
    CONCAT(n.n_name, ' - ', r.r_name) AS loc_info,
    s.s_name AS supplier_name,
    s.s_acctbal
FROM 
    CustomerOrders c
JOIN 
    nation n ON c.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rank <= 5
WHERE 
    c.total_spent > 1000
ORDER BY 
    c.total_spent DESC, c.c_name ASC
LIMIT 10
UNION ALL
SELECT 
    'TOTAL' AS c_name,
    SUM(c.total_spent) AS total_spent,
    NULL AS loc_info,
    NULL AS supplier_name,
    NULL AS s_acctbal
FROM 
    CustomerOrders c
WHERE 
    c.total_spent IS NOT NULL;
