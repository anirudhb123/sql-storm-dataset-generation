WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ROUND(AVG(l.l_discount), 2) AS avg_discount,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
RegionNation AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    ps.s_name AS supplier_name,
    ps.total_available,
    os.order_count,
    os.total_spent,
    pd.p_name,
    pd.avg_discount,
    pd.total_quantity,
    rn.r_name AS region_name,
    rn.n_name AS nation_name
FROM 
    SupplierStats ps
LEFT JOIN 
    OrderSummary os ON ps.s_suppkey IN (SELECT ps2.ps_suppkey FROM partsupp ps2 WHERE ps2.ps_availqty > 100)
JOIN 
    PartDetails pd ON pd.total_quantity > 50
JOIN 
    RegionNation rn ON ps.s_suppkey IN (SELECT ps3.ps_suppkey FROM partsupp ps3 JOIN supplier s3 ON ps3.ps_suppkey = s3.s_suppkey WHERE s3.s_nationkey = nn.n_nationkey)
WHERE 
    os.total_spent > 1000
ORDER BY 
    ps.total_available DESC, os.total_spent DESC;
