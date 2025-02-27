WITH RECURSIVE supplier_rank AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey
),
part_supplier_summary AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
region_nation AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    INNER JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)

SELECT 
    r.r_name AS region_name,
    JSON_AGG(DISTINCT json_build_object('supplier_id', sr.s_suppkey, 'supplier_name', sr.s_name, 'supplier_balance', sr.s_acctbal)) AS suppliers,
    ps.total_available,
    ps.avg_cost,
    cn.total_spent,
    cn.order_count,
    CASE 
        WHEN sr.rank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier' 
    END AS supplier_status
FROM 
    region_nation r
LEFT JOIN 
    supplier_rank sr ON r.nation_count > 3 AND sr.rank <= 5
LEFT JOIN 
    part_supplier_summary ps ON ps.ps_partkey IN (SELECT p.p_partkey 
                                                   FROM part p
                                                   WHERE p.p_retailprice > (SELECT AVG(p_retailprice) 
                                                                             FROM part)
                                                   ORDER BY p.p_partkey DESC 
                                                   LIMIT 10)
LEFT JOIN 
    customer_orders cn ON cn.c_custkey = sr.s_suppkey
WHERE 
    ps.total_available IS NOT NULL 
    AND (sr.s_acctbal IS NULL OR sr.s_acctbal > 5000.00)
GROUP BY 
    r.r_name, ps.total_available, ps.avg_cost, cn.total_spent, cn.order_count, sr.rank
ORDER BY 
    r.r_name ASC, ps.total_available DESC;
