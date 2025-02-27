WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATEADD(MONTH, -1, CURRENT_DATE) AND CURRENT_DATE
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COALESCE(SUM(RP.p_retailprice), 0) AS total_retail_value,
    COUNT(DISTINCT SS.s_suppkey) AS total_suppliers,
    SUM(OS.total_price) AS total_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedParts RP ON RP.price_rank <= 10
FULL OUTER JOIN 
    SupplierStats SS ON SS.part_count > 5
INNER JOIN 
    OrderDetails OS ON OS.item_count > 3
WHERE 
    n.n_name NOT LIKE '%land%' 
    AND r.r_comment IS NOT NULL 
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(RP.p_retailprice) > 1000 
    OR COUNT(DISTINCT SS.s_suppkey) = 0
ORDER BY 
    total_order_value DESC, total_retail_value ASC;
