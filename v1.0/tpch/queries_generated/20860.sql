WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
PartPrices AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
NullCheck AS (
    SELECT 
        p.p_partkey,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price' 
            ELSE p.p_name 
        END AS product_name
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL AND (p.p_brand IS NULL OR p.p_brand = 'Brand#23')
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    p.product_name,
    MAX(l.total_lineitem_value) AS max_order_value,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(p.p_retailprice * (1 + CASE 
               WHEN p.p_retailprice > 100 THEN 0.1
               ELSE 0 
            END)) AS adjusted_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    NullCheck p ON p.p_partkey IS NOT NULL
LEFT JOIN 
    rankedSuppliers s ON s.s_nationkey = n.n_nationkey AND s.rank <= 5
LEFT JOIN 
    AggregatedLineItems l ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
GROUP BY 
    r.r_name, c.c_name, p.product_name
HAVING 
    SUM(p.p_retailprice) IS NOT NULL AND COUNT(s.s_suppkey) > 0
ORDER BY 
    r.r_name DESC, max_order_value DESC;
