WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
HighQuantityLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        CASE 
            WHEN SUM(l.l_discount) > 0.1 THEN 'High Discount'
            ELSE 'Regular'
        END AS discount_type
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(s.total_cost), 0) AS total_supplier_cost,
    MAX(hl.total_quantity) AS max_quantity,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', hl.discount_type)) AS supplier_discount_types
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierInfo s ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
LEFT JOIN 
    HighQuantityLineItems hl ON o.o_orderkey = hl.l_orderkey
WHERE 
    r.r_name LIKE 'A%' AND 
    (s.s_acctbal IS NOT NULL OR o.o_totalprice IS NULL)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    r.r_name DESC;
