WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionNation AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    COALESCE(SUM(RP.p_retailprice), 0) AS total_product_value,
    SUM(si.avg_supplycost * si.part_count) AS total_supplier_cost,
    MAX(COALESCE(cs.last_order_date, '1970-01-01')) AS most_recent_order,
    MAX(CASE 
            WHEN COUNT(nn.supplier_count) = 0 THEN 'No Suppliers' 
            ELSE 'Suppliers Exist' 
        END) AS supplier_status
FROM 
    RegionNation nn
LEFT JOIN 
    SupplierInfo si ON nn.n_nationkey = si.s_nationkey
LEFT JOIN 
    CustomerOrderStats cs ON nn.n_nationkey = cs.c_custkey
LEFT JOIN 
    RankedParts RP ON RP.p_partkey = si.part_count
GROUP BY 
    r.r_name
HAVING 
    SUM(RP.p_retailprice) IS NOT NULL
ORDER BY 
    total_customers DESC, total_product_value DESC;
