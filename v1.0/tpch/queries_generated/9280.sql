WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_per_brand
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), nation_stats AS (
    SELECT 
        n.n_name, 
        COUNT(s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
), order_summary AS (
    SELECT 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    rp.p_brand, 
    rp.p_name, 
    rp.total_supply_cost, 
    ns.n_name, 
    ns.total_suppliers, 
    ns.total_supplier_balance, 
    os.c_name, 
    os.total_orders, 
    os.total_revenue
FROM 
    ranked_parts rp
JOIN 
    region rg ON rg.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey LIMIT 1) LIMIT 1)
JOIN 
    nation_stats ns ON ns.total_suppliers > 10
JOIN 
    order_summary os ON os.total_orders > 5
WHERE 
    rp.rank_per_brand <= 5
ORDER BY 
    rp.total_supply_cost DESC, 
    os.total_revenue DESC;
