
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
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM( li.l_extendedprice * (1 - li.l_discount) ) AS total_revenue,
        COUNT(DISTINCT li.l_linenumber) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.total_lines,
        CASE 
            WHEN os.total_revenue > (SELECT AVG(total_revenue) * 1.1 FROM OrderSummaries) THEN 'High Value'
            ELSE 'Regular'
        END AS order_type
    FROM 
        OrderSummaries os
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
    COALESCE(MIN(ps.ps_supplycost), 0) AS min_supply_cost,
    COALESCE(MAX(ps.ps_supplycost), 0) AS max_supply_cost,
    SUM(CASE WHEN hvo.order_type = 'High Value' THEN 1 ELSE 0 END) AS high_value_order_count,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'CANADA')) AS canadian_customer_count,
    s.s_name AS supplier_name,
    CASE 
        WHEN COUNT(DISTINCT l.l_orderkey) > 10 THEN 'Many Orders'
        ELSE 'Few Orders'
    END AS order_relationship
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name
ORDER BY 
    total_available DESC,
    p.p_partkey
LIMIT 100
OFFSET (SELECT COUNT(DISTINCT n.n_nationkey) * COALESCE(MAX(NULLIF(s.s_acctbal, 0)), 1) FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey);
