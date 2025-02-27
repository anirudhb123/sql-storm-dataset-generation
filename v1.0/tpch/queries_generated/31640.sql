WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
nation_stats AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
),
part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    n.n_name AS supplier_nation,
    psi.p_name,
    psi.total_available_quantity,
    psi.total_supply_cost,
    COALESCE(n_stats.supplier_count, 0) AS supplier_count,
    COALESCE(n_stats.avg_acctbal, 0) AS avg_acctbal,
    CASE 
        WHEN co.o_totalprice > 10000 THEN 'High Value' 
        ELSE 'Regular' 
    END AS order_value_category
FROM 
    customer_orders co
LEFT JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
LEFT JOIN 
    part_supplier_info psi ON li.l_partkey = psi.p_partkey
LEFT JOIN 
    nation_stats n_stats ON li.l_suppkey = n_stats.n_nationkey
WHERE 
    (co.order_rank <= 5 OR co.o_totalprice > 5000)
    AND (n_stats.supplier_count IS NULL OR n_stats.avg_acctbal > 1000)
ORDER BY 
    co.c_custkey, co.o_orderdate DESC, psi.p_name;
