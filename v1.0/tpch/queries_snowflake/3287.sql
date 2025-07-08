
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice END) AS max_final_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(cs.total_spent, 0.00) AS total_spent,
    cs.max_final_order_price,
    p.p_retailprice * 1.1 AS adjusted_retail_price,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.supplier_rank <= 3
LEFT JOIN 
    OrderInfo o ON ps.ps_partkey = o.o_orderkey
LEFT JOIN 
    CustomerOrderSummary cs ON cs.c_custkey = o.o_orderkey
WHERE 
    (p.p_size > 10 AND p.p_type LIKE '%brass%') OR (p.p_container IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, cs.order_count, cs.total_spent, cs.max_final_order_price, p.p_retailprice
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 0
ORDER BY 
    adjusted_retail_price DESC, total_orders ASC;
