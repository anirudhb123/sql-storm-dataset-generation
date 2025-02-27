WITH RECURSIVE supp_chain AS (
    SELECT s.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000.00
    UNION ALL
    SELECT s.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN supp_chain sc ON s.s_nationkey = sc.n_nationkey
    WHERE s.s_acctbal > 10000.00 AND sc.level < 5
),
suppliers_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT sc.supp_chain.s_suppkey) AS related_suppliers_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN supp_chain sc ON s.s_suppkey = sc.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_lineitem) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_price,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    si.s_name AS supplier_name,
    si.total_supply_cost,
    si.related_suppliers_count,
    os.lineitem_count,
    os.total_price,
    CASE 
        WHEN os.price_rank = 1 THEN 'Highest Priced Order'
        ELSE 'Other Orders' 
    END AS order_type
FROM nation n
JOIN suppliers_info si ON n.n_nationkey = si.s_nationkey
FULL OUTER JOIN order_summary os ON os.lineitem_count IS NOT NULL OR si.related_suppliers_count IS NULL
WHERE si.total_supply_cost IS NOT NULL AND (os.total_price > 10000.00 OR si.related_suppliers_count > 0)
ORDER BY si.total_supply_cost DESC, os.total_price ASC;
