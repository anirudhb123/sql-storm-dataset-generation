WITH RECURSIVE price_hikes AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        0 AS price_increase,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS price_status
    FROM part p
    WHERE p.p_retailprice IS NOT NULL

    UNION ALL

    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice * 1.10 AS updated_price,
        ph.price_increase + (p.p_retailprice * 0.10) AS price_increase,
        'Known' AS price_status
    FROM part p
    JOIN price_hikes ph ON p.p_partkey = ph.p_partkey
    WHERE ph.price_increase < 100
),

supplier_nation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),

customers_with_top_suppliers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(sn.nation_name, 'No Nation') AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY COALESCE(sn.nation_name, 'No Nation') ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN supplier_nation sn ON sn.s_suppkey = l.l_suppkey
    GROUP BY c.c_custkey, c.c_name, sn.nation_name
)

SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_retailprice,
    c.total_spent,
    c.nation_name,
    CASE 
        WHEN c.spending_rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    CASE 
        WHEN ph.price_status = 'Unknown' THEN 'Price Unknown'
        ELSE 'Price Known'
    END AS pricing_info
FROM price_hikes ph
LEFT JOIN customers_with_top_suppliers c ON ph.p_partkey IN (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_supplycost <= c.total_spent)
WHERE ph.price_increase > 0 OR c.total_spent IS NOT NULL
ORDER BY ph.p_partkey, c.total_spent DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM price_hikes) / 2;
