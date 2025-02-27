WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        CASE 
            WHEN p.p_retailprice > (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_partkey = p.p_partkey) THEN 'High'
            ELSE 'Low' 
        END AS value_category
    FROM part p
),
OrderAmounts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n 
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_acctbal,
    hp.value_category,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    MIN(oa.total_amount) AS min_order_amount,
    MAX(oa.total_amount) AS max_order_amount
FROM NationSummary ns
LEFT JOIN RankedSuppliers rs ON ns.n_nationkey = rs.s_suppkey 
    AND rs.rank = 1
LEFT JOIN HighValueParts hp ON hp.p_partkey IN 
    (SELECT ps.ps_partkey FROM partsupp ps LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = ns.n_nationkey)
LEFT JOIN OrderAmounts oa ON oa.o_orderkey IN 
    (SELECT o.o_orderkey FROM orders o LEFT JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey = ns.n_nationkey)
GROUP BY 
    ns.n_name, ns.supplier_count, ns.total_acctbal, hp.value_category, rs.s_name
HAVING 
    SUM(CASE WHEN hp.value_category = 'High' THEN 1 ELSE 0 END) > 0
ORDER BY 
    ns.n_name, max_order_amount DESC NULLS LAST;
