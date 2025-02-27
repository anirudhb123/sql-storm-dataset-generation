WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    
    UNION ALL
    
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ps.total_avail_qty) AS total_available_quantity,
    SUM(os.total_price) AS total_order_value,
    ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY SUM(os.total_price) DESC) AS rank
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    customer c ON ch.c_custkey = c.c_custkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    PartSupplier ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
LEFT JOIN 
    OrderSummary os ON o.o_orderkey = os.o_orderkey
GROUP BY 
    c.c_name, ch.level
HAVING 
    SUM(os.total_price) > 5000
ORDER BY 
    rank, c.c_name;
