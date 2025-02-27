WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_discounted_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1994-01-01' AND o.o_orderdate < '1995-01-01'
),
SupplierInfo AS (
    SELECT DISTINCT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) OVER (PARTITION BY s.s_suppkey) AS supply_parts_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(MAX(CASE WHEN ps.ps_supplycost > 100 THEN 'High' ELSE 'Low' END), 'Unknown') AS cost_category,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.o_orderkey,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    ROUND(AVG(pd.total_quantity), 2) AS avg_quantity_per_part,
    SUM(CASE WHEN r.o_orderstatus = 'O' THEN r.total_discounted_price ELSE 0 END) AS total_open_orders_discounted_price,
    STRING_AGG(CONCAT(pd.p_name, ' - ', pd.cost_category), '; ') AS part_info
FROM 
    RankedOrders r
JOIN 
    SupplierInfo s ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal < 1000))
LEFT JOIN 
    PartDetails pd ON pd.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.rank_status <= 10
GROUP BY 
    r.o_orderkey
HAVING 
    COUNT(DISTINCT pd.p_partkey) >= 5
ORDER BY 
    total_suppliers DESC, avg_quantity_per_part DESC;
