WITH regional_supplier AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
lineitem_statistics AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(*) AS total_lineitems,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(rn.supplier_count, 0) AS supplier_count,
    COALESCE(cos.total_orders, 0) AS customer_orders,
    COALESCE(cos.total_spent, 0) AS total_spent_by_customers,
    ls.total_lineitems,
    ls.avg_quantity
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    regional_supplier rn ON rn.nation_name IN (SELECT n_name FROM nation WHERE n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey))
LEFT JOIN 
    customer_order_summary cos ON cos.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = cos.c_custkey))
LEFT JOIN 
    lineitem_statistics ls ON ls.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container = p.p_container) 
    OR p.p_mfgr LIKE '%Brand%'
ORDER BY 
    p.p_name;
