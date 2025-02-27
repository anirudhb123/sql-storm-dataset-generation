WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name
    FROM 
        customer c
        JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS region,
    s.s_name AS supplier_name,
    h.c_name AS customer_name,
    o.o_orderkey,
    o.total_amount,
    o.unique_parts,
    o.avg_quantity,
    CASE 
        WHEN o.total_amount > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_category
FROM 
    RankedSuppliers s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN HighValueCustomers h ON s.s_nationkey = h.c_nationkey
    JOIN OrderDetails o ON h.c_custkey = (SELECT o1.o_custkey FROM orders o1 WHERE o1.o_orderkey = o.o_orderkey)
WHERE 
    s.rn = 1
ORDER BY 
    r.r_name, s.s_name, h.c_name;
