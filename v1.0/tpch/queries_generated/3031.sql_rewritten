WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_nationkey, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        orders o
    INNER JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
HighValueOrders AS (
    SELECT 
        co.o_orderkey,
        co.o_totalprice,
        CASE 
            WHEN l.total_value IS NULL THEN 0
            ELSE l.total_value
        END AS calculated_value
    FROM 
        CustomerOrders co
    LEFT JOIN 
        LineItemDetails l ON co.o_orderkey = l.l_orderkey
    WHERE 
        co.o_orderdate >= DATE '1996-01-01'
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
    AVG(h.calculated_value) AS average_value,
    SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_balance
FROM 
    HighValueOrders h
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = h.o_orderkey))
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers s ON s.rank <= 5 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 15))
GROUP BY 
    r.r_name
ORDER BY 
    high_value_order_count DESC;