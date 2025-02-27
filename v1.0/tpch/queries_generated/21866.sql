WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 10
    AND p.p_container IS NOT NULL
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comment available') AS s_comment_cleaned
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
), FilteredLineItems AS (
    SELECT 
        l.*, 
        SUM(l.l_quantity) OVER (PARTITION BY l.l_orderkey) AS total_quantity
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.15
)
SELECT 
    r.r_name,
    p.p_name,
    sp.s_name,
    ci.c_name,
    COALESCE(filtered.qty, 0) AS qty_filtered,
    ROUND(SUM(li.l_extendedprice * (1 - li.l_discount)), 2) AS revenue,
    RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) as rank_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierInfo sp ON sp.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT p_partkey FROM RankedParts WHERE rn = 1)
)
LEFT JOIN FilteredLineItems li ON sp.s_suppkey = li.l_suppkey
LEFT JOIN CustomerOrders ci ON ci.order_count > 5
LEFT JOIN RankedParts p ON li.l_partkey = p.p_partkey
GROUP BY r.r_name, p.p_name, sp.s_name, ci.c_name, filtered.qty
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY r.r_name, revenue DESC;
