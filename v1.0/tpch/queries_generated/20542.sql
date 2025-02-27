WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_mktsegment,
        CASE 
            WHEN o.o_totalprice > 10000 THEN 'High'
            WHEN o.o_totalprice BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS price_category
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 200
),
FrequentLineItems AS (
    SELECT 
        l.l_partkey,
        COUNT(*) AS frequency
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
    HAVING 
        COUNT(*) > 5
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(ps.ps_availqty, 0), 1) AS available_quantity -- Avoid division by zero
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS average_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MIN(DATEDIFF(DAY, o.o_orderdate, GETDATE())) AS days_since_order
FROM 
    HighValueOrders o
JOIN 
    RankedSuppliers s ON s.rank = 1 -- Join with top supplier per nation
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    TopParts p ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE 
    o.price_category = 'High'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > (SELECT COUNT(*) FROM orders) / 10
ORDER BY 
    total_revenue DESC;
