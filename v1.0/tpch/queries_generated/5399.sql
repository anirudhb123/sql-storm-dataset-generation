WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
), customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
), nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT nh.s_suppkey) AS total_suppliers,
    SUM(nh.total_supply_cost) AS total_supply_cost,
    cs.total_spent,
    cs.order_count,
    ns.total_count,
    ns.total_acctbal
FROM 
    region r
LEFT JOIN 
    supplier_hierarchy nh ON nh.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN 
    customer_orders cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey))
LEFT JOIN 
    nation_summary ns ON ns.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
GROUP BY 
    r.r_name, cs.total_spent, cs.order_count, ns.total_acctbal
ORDER BY 
    total_supply_cost DESC, total_spent DESC NULLS LAST;
