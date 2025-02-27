WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_size DESC) AS rank_size
    FROM part p
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY s.s_suppkey
),
FilteredSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_orders DESC) AS order_rank
    FROM SupplierSales ss
    WHERE ss.total_sales > (SELECT AVG(total_sales) FROM SupplierSales)
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS nation_sales
    FROM FilteredSuppliers fs
    JOIN supplier s ON fs.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING nation_sales > (SELECT MAX(nation_sales) FROM (SELECT SUM(total_sales) AS nation_sales FROM FilteredSuppliers fs JOIN supplier s ON fs.s_suppkey = s.s_suppkey GROUP BY s.s_nationkey) AS sub)
)
SELECT 
    r.r_name,
    tp.n_name,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(CASE WHEN l.l_returnflag = 'Y' THEN l.l_discount ELSE NULL END) AS avg_return_discount,
    STRING_AGG(DISTINCT l.l_comment ORDER BY l.l_linestatus) AS comments,
    COUNT(DISTINCT l.l_orderkey) AS order_count
FROM region r
LEFT JOIN nation tp ON r.r_regionkey = tp.n_regionkey
LEFT JOIN RankedParts rp ON tp.n_nationkey = rp.p_partkey
LEFT JOIN lineitem l ON rp.p_partkey = l.l_partkey OR l.l_quantity IS NULL
INNER JOIN TopNations tn ON tn.n_nationkey = tp.n_nationkey
GROUP BY r.r_name, tp.n_name, rp.p_name, rp.p_retailprice
HAVING COUNT(DISTINCT l.l_orderkey) > 10 AND (SUM(l.l_extendedprice) IS NULL OR SUM(l.l_extendedprice) < 10000)
ORDER BY total_quantity DESC, avg_return_discount DESC, r.r_name;
