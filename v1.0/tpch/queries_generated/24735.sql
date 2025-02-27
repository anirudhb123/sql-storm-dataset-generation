WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
), CTE_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2023-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CustomerPartDetails AS (
    SELECT 
        c.c_custkey, 
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS cust_total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        COUNT(DISTINCT l.l_partkey) AS parts_purchased
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    c.c_custkey, 
    c.c_name,
    cpd.cust_total_spent,
    cpd.last_order_date,
    rs.s_name AS top_supplier,
    (SELECT 
         COUNT(*) 
     FROM 
         lineitem l 
     WHERE 
         l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
         AND l.l_shipdate > '2022-01-01') AS total_items_shipped
FROM 
    customer c
JOIN 
    CustomerPartDetails cpd ON c.c_custkey = cpd.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON cpd.distinct_parts = rs.rank
WHERE 
    rs.rank = 1 
    AND cpd.last_order_date IS NOT NULL
ORDER BY 
    cpd.cust_total_spent DESC
LIMIT 10;
