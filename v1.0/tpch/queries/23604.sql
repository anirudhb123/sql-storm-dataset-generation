
WITH RECURSIVE OrderHierarchy AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_orderstatus,
        CAST(0 AS INTEGER) AS level
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1995-01-01'
    UNION ALL
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_orderstatus,
        oh.level + 1
    FROM
        orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE
        o.o_orderkey > oh.o_orderkey
),
CustomerCriticalData AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(l.l_shipdate) AS last_order_date,
        AVG(l.l_discount) AS average_discount
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_acctbal
),
HighSpender AS (
    SELECT
        ccd.c_custkey,
        ccd.c_name,
        ccd.total_spent,
        ccd.order_count,
        ROW_NUMBER() OVER (PARTITION BY ccd.c_custkey ORDER BY ccd.total_spent DESC) AS rn
    FROM
        CustomerCriticalData ccd
    WHERE
        ccd.total_spent > (
            SELECT AVG(total_spent) FROM CustomerCriticalData
        )
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN SUM(l.l_extendedprice * (1 - l.l_discount)) / COUNT(DISTINCT o.o_orderkey)
        ELSE NULL
    END AS average_revenue_per_order,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM HighSpender hs
            WHERE hs.total_spent > 10000 AND hs.c_custkey = c.c_custkey
        ) THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM 
    partsupp ps
JOIN 
    part ph ON ps.ps_partkey = ph.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = ph.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    ph.p_partkey, ph.p_name, s.s_name, c.c_custkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC;
