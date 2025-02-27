WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        total_value > 1000
),
OrderLineSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    c.c_name AS customer_name,
    h.p_name AS high_value_part,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    ols.total_quantity,
    ols.avg_discount,
    CASE 
        WHEN c.total_spent IS NULL THEN 0
        ELSE c.total_spent
    END AS total_spent_amount
FROM 
    CustomerOrderSummary c
LEFT JOIN 
    HighValueParts h ON h.total_value > 5000 
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND h.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 50)
JOIN 
    OrderLineSummary ols ON ols.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    c.order_count > 5
ORDER BY 
    c.c_name, h.p_name;
