WITH RECURSIVE cte_order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
ct_distinct_part AS (
    SELECT 
        DISTINCT p.p_partkey, 
        p.p_name,
        p.p_brand
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
supplier_order_details AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(CASE 
            WHEN (s.s_acctbal IS NULL OR s.s_acctbal < 0) THEN 0 
            ELSE s.s_acctbal 
        END) AS total_balance 
    FROM 
        supplier s
    FULL OUTER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        orders o ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%complicated%')
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name,
    SUM(o.o_totalprice) AS total_sales,
    COUNT(DISTINCT CASE 
        WHEN c.c_nationkey IS NULL THEN 'No Nation'
        ELSE c.c_name 
    END) AS distinct_customer_count,
    SUM(DISTINCT so.order_count) AS distinct_order_count,
    STRING_AGG(DISTINCT CONCAT_WS(' | ', p.p_name, CAST(so.avg_supply_cost AS VARCHAR)) 
               ORDER BY p.p_name) AS supply_details
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    supplier_order_details so ON so.s_suppkey = (SELECT MIN(s.s_suppkey) FROM supplier s)
LEFT JOIN 
    ct_distinct_part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND (o.o_totalprice IS NOT NULL OR o.o_totalprice > 1000.00)
GROUP BY 
    n.n_name 
HAVING 
    SUM(o.o_totalprice) IS NOT NULL 
    AND COUNT(o.o_orderkey) > 0 
ORDER BY 
    total_sales DESC;
