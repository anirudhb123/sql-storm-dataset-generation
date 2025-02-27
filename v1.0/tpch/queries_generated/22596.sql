WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE) 
            THEN 'High' 
            ELSE 'Low' 
        END AS price_category
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    hvo.price_category,
    spc.supplier_count,
    MAX(l.l_extendedprice) as max_extended_price,
    ROUND(AVG(l.l_discount) * 100, 2) AS avg_discount_percentage
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
LEFT JOIN 
    SupplierPartCounts spc ON p.p_partkey = spc.ps_partkey
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 500.00 
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    p.p_name, rs.s_name, hvo.price_category, spc.supplier_count
ORDER BY 
    p.p_name, supplier_name DESC, avg_discount_percentage ASC;
