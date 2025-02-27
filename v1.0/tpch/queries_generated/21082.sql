WITH RankedParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS price_rank
    FROM 
        part
    WHERE 
        p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part))
),
SupplierAgg AS (
    SELECT 
        s_nationkey, 
        COUNT(DISTINCT s_suppkey) AS supplier_count, 
        SUM(s_acctbal) AS total_acctbal
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
EligibleSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sa.supplier_count,
        sa.total_acctbal
    FROM 
        supplier s
    JOIN 
        SupplierAgg sa ON s.s_nationkey = sa.s_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
        AND EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_acctbal < 1000)
    GROUP BY
        o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(es.s_name, 'No Supplier') AS supplier_name,
    os.total_revenue,
    os.customer_count,
    CASE 
        WHEN os.customer_count > 0 THEN os.total_revenue / os.customer_count 
        ELSE NULL 
    END AS avg_revenue_per_customer
FROM 
    RankedParts rp
LEFT JOIN 
    EligibleSuppliers es ON rp.price_rank = 1 AND es.total_acctbal > 5000
LEFT JOIN 
    OrderStats os ON os.total_revenue > 1000 
WHERE 
    rp.p_partkey IS NOT NULL
ORDER BY 
    rp.p_retailprice DESC, 
    avg_revenue_per_customer DESC;
