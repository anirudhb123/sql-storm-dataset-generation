WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        PS.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM part p
    JOIN partsupp PS ON p.p_partkey = PS.ps_partkey
),
qualified_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS supplier_comment
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2 
        WHERE s2.s_nationkey = s.s_nationkey
    )
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 0
),
final_selection AS (
    SELECT 
        r.r_name,
        np.n_name AS nation_name,
        rp.p_name,
        cs.s_name,
        Coalesce(cs.s_acctbal, 0) AS supplier_balance,
        co.order_count,
        co.total_spent,
        CASE 
            WHEN co.total_spent > 10000 THEN 'High Roller'
            WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Player'
            ELSE 'Low Spender'
        END AS customer_category
    FROM region r
    JOIN nation np ON r.r_regionkey = np.n_regionkey
    JOIN qualified_suppliers cs ON np.n_nationkey = cs.s_nationkey
    JOIN ranked_parts rp ON cs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 5
    )
    JOIN customer_orders co ON co.c_custkey = cs.s_nationkey
    WHERE rp.rank_by_price <= 10
)
SELECT 
    fs.nation_name,
    fs.r_name,
    fs.p_name,
    fs.s_name,
    fs.supplier_balance,
    fs.order_count,
    fs.customer_category
FROM final_selection fs
WHERE fs.supplier_balance IS NOT NULL
ORDER BY fs.nation_name, fs.order_count DESC, fs.supplier_balance;
