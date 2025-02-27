WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT 
        n.n_name, 
        r.r_name,
        COUNT(*) AS nation_count 
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    p.p_name,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(AVG(l.l_discount), 0) AS avg_discount,
    MAX(o.o_totalprice) AS max_total_price,
    SUM(s.total_supply_cost) AS total_supply_cost
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
FULL OUTER JOIN 
    SupplierInfo s ON l.l_suppkey = s.s_suppkey
JOIN 
    NationRegion nr ON nr.nation_count > 1 
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (o.o_orderstatus IS NOT NULL OR s.s_name IS NULL)
    AND (p.p_retailprice > 50 OR p.p_container LIKE '%box%')
    AND (l.l_returnflag = 'N' AND l.l_shipdate IS NOT NULL)
GROUP BY 
    p.p_name, n.n_name, r.r_name
HAVING 
    SUM(CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END) > 0
ORDER BY 
    region_name, nation_name;
