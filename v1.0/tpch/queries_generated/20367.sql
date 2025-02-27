WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_size DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments available') AS supplier_comment
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
), 
CustomerWithNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        n.n_name IS NOT NULL
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
FinalAggregation AS (
    SELECT 
        cp.c_custkey,
        cp.c_name,
        ds.s_suppkey,
        COUNT(DISTINCT op.o_orderkey) AS order_count,
        SUM(op.total_price) AS total_spent,
        COUNT(DISTINCT rp.p_partkey) AS parts_ordered
    FROM 
        CustomerWithNation cp
    LEFT JOIN 
        OrderSummary op ON cp.c_custkey = op.o_custkey
    LEFT JOIN 
        partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM RankedParts p WHERE p.brand_rank <= 5)
    LEFT JOIN 
        SupplierDetails ds ON ps.ps_suppkey = ds.s_suppkey
    GROUP BY 
        cp.c_custkey, cp.c_name, ds.s_suppkey
    HAVING 
        SUM(op.total_price) > 1000
        OR COUNT(DISTINCT op.o_orderkey) > 10
), 
FinalOutput AS (
    SELECT 
        fa.c_custkey,
        fa.c_name,
        fa.s_suppkey,
        COALESCE(fa.total_spent, 0) AS total_spent,
        COALESCE(fa.order_count, 0) AS order_count,
        COALESCE(fa.parts_ordered, 0) AS parts_ordered,
        RANK() OVER (ORDER BY fa.total_spent DESC, fa.order_count DESC) AS customer_rank
    FROM 
        FinalAggregation fa
)
SELECT 
    fo.*,
    CASE 
        WHEN fo.total_spent > 5000 THEN 'High Roller'
        WHEN fo.order_count > 20 THEN 'Frequent Buyer'
        ELSE 'Occasional Shopper' 
    END AS shopper_category
FROM 
    FinalOutput fo 
WHERE 
    (fo.customer_rank <= 10 OR fo.parts_ordered IS NULL)
ORDER BY 
    fo.total_spent DESC, fo.customer_rank;
