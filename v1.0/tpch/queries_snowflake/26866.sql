
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplies AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supply_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS lineitem_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    COALESCE(ps.supply_count, 0) AS supply_count,
    COALESCE(ps.total_available_qty, 0) AS total_available_qty,
    COALESCE(od.total_revenue, 0) AS total_revenue,
    COALESCE(od.lineitem_count, 0) AS lineitem_count,
    sd.nation_name,
    sd.region_name,
    sd.comment_length
FROM 
    part p
LEFT JOIN 
    PartSupplies ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = p.p_partkey)
LEFT JOIN 
    SupplierDetails sd ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
WHERE 
    UPPER(p.p_comment) LIKE '%IMPORTANT%'
ORDER BY 
    sd.comment_length DESC, 
    od.total_revenue DESC;
