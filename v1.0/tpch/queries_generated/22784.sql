WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown Price'
            WHEN p.p_retailprice > 1000 THEN 'Expensive'
            ELSE 'Affordable'
        END AS price_category
    FROM part p
    WHERE p.p_comment LIKE '%fragile%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
),
OuterJoinNation AS (
    SELECT 
        n.n_name,
        COALESCE(cs.order_count, 0) AS total_orders,
        SUM(l.l_discount) AS total_discounted
    FROM nation n
    LEFT JOIN CustomerOrders cs ON n.n_nationkey = cs.c_custkey
    LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    GROUP BY n.n_name, cs.order_count
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    fs.order_count,
    COALESCE(rnk, 0) AS supplier_rank,
    CASE 
        WHEN total_orders > 10 THEN 'High Value Customer'
        WHEN total_orders BETWEEN 5 AND 10 THEN 'Moderate Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment,
    STRING_AGG(DISTINCT n.n_name || ' - ' || total_discounted, ', ') AS nation_discounts
FROM FilteredParts p
JOIN RankedSuppliers r ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = r.s_suppkey)
LEFT JOIN OuterJoinNation fs ON fs.total_orders IS NOT NULL
WHERE p.p_retailprice IS NOT NULL
GROUP BY p.p_name, p.p_brand, p.p_retailprice, fs.order_count, rnk
HAVING AVG(p.p_retailprice) < (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY price_category DESC, total_orders DESC, p.p_retailprice ASC
LIMIT 100;
