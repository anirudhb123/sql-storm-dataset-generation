WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), 
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance' 
            WHEN s.s_acctbal >= 1000 THEN 'High Value' 
            ELSE 'Regular Supplier' 
        END AS supplier_category
    FROM supplier s
    WHERE s.s_comment NOT LIKE '%obsolete%' AND s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_comment IS NOT NULL
    )
), 
ExtensiveOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority
)

SELECT 
    COUNT(DISTINCT fp.p_partkey) AS total_filtered_parts,
    SUM(fo.lineitem_count) AS total_order_lineitems,
    MAX(COALESCE(ps.ps_supplycost, 0)) AS max_supply_cost,
    AVG(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_availqty ELSE NULL END) AS avg_available_qty,
    STRING_AGG(DISTINCT fs.s_name || ' (' || fs.s_acctbal || ')', ', ') AS supplier_info
FROM RankedParts rp
FULL OUTER JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN ExtensiveOrders fo ON fo.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'O' 
      AND o.o_totalprice > 5000
)
WHERE rp.brand_rank <= 3 OR fs.supplier_category = 'High Value'
GROUP BY rp.p_type
HAVING COUNT(DISTINCT fs.s_suppkey) > 2 OR SUM(fo.lineitem_count) > 15
ORDER BY total_filtered_parts DESC, avg_available_qty ASC;
