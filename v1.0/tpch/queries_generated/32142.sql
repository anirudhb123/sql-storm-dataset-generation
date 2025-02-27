WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS depth
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 100.00
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        depth + 1
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        SupplyChain sc ON sc.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 50
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    MAX(s.s_acctbal) AS max_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(CASE WHEN os.rank <= 10 THEN os.total_revenue ELSE 0 END) AS top_order_revenue
FROM 
    part p
LEFT OUTER JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    OrderSummary os ON os.o_orderkey = ps.ps_partkey
WHERE 
    p.p_size BETWEEN 1 AND 20 
    AND p.p_container IS NOT NULL 
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_cost DESC, 
    max_supplier_balance ASC;
