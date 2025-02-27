
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(l.l_linenumber) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(ss.total_cost, 0) AS supplier_total_cost,
    COALESCE(cos.total_spent, 0) AS customer_total_spent,
    RANK() OVER (ORDER BY rp.p_retailprice DESC) AS retail_rank,
    CASE 
        WHEN rp.p_retailprice > 100 THEN 'Expensive' 
        WHEN rp.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate' 
        ELSE 'Cheap' 
    END AS price_category,
    CASE 
        WHEN rp.price_rank = 1 THEN 'Top Price'
        ELSE 'Regular Price'
    END AS rank_description
FROM RankedParts rp
LEFT JOIN SupplierSummary ss ON rp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY ps.ps_partkey
)
LEFT JOIN CustomerOrders cos ON EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE cos.c_custkey = o.o_custkey 
    AND o.o_orderdate > CURRENT_DATE - INTERVAL '6 months'
)
WHERE rp.price_rank <= 5 OR rp.p_retailprice IS NULL
ORDER BY rp.p_partkey;
