WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
),
NationDetails AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        r.r_name AS region_name,
        CASE 
            WHEN COUNT(s.s_suppkey) = 0 THEN 'No Suppliers' 
            ELSE 'Suppliers Exist' 
        END AS supplier_status
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        (SELECT AVG(p2.p_retailprice) FROM part p2) AS avg_price_difference
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) AND 
        p.p_retailprice < (SELECT MAX(p_retailprice) FROM part)
),
OrderAggregation AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FinalQuery AS (
    SELECT 
        nd.region_name,
        nd.n_name,
        COUNT(DISTINCT hs.s_suppkey) AS supplier_count,
        COUNT(DISTINCT hp.p_partkey) AS high_value_parts_count,
        AVG(oa.total_revenue) AS average_revenue,
        SUM(CASE 
            WHEN oa.total_revenue > 10000 THEN 1 
            ELSE 0 
        END) AS high_value_order_count
    FROM 
        NationDetails nd
    LEFT JOIN 
        RankedSuppliers hs ON hs.rank_within_nation = 1 
    LEFT JOIN 
        HighValueParts hp ON hp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
    LEFT JOIN 
        OrderAggregation oa ON oa.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
    GROUP BY 
        nd.region_name, nd.n_name
)
SELECT 
    *
FROM 
    FinalQuery
WHERE 
    supplier_count > 0 AND 
    high_value_parts_count > 0
ORDER BY 
    region_name, n_name;
