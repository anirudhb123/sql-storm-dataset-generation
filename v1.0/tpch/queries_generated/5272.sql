WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    pt.p_name,
    pt.p_brand,
    pt.p_container,
    s.s_name AS supplier_name,
    cs.total_spent,
    cs.order_count,
    cs.lineitem_count,
    ns.supplier_count,
    ns.total_acct_balance
FROM 
    part pt
JOIN 
    partsupp ps ON pt.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer_orders cs ON cs.c_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = s.s_nationkey LIMIT 1)
JOIN 
    nation_summary ns ON ns.n_nationkey = s.s_nationkey
WHERE 
    pt.p_retailprice > 50.00
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
