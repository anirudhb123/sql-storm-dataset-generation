WITH nation_stats AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
product_stats AS (
    SELECT 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_availqty, 
        AVG(p.p_retailprice) AS avg_retailprice
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
),
order_summary AS (
    SELECT 
        c.c_name, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_name, o.o_orderkey
)
SELECT 
    ns.n_name AS nation_name, 
    ns.supplier_count, 
    ns.total_acctbal, 
    ps.p_name AS product_name, 
    ps.total_availqty, 
    ps.avg_retailprice, 
    os.c_name AS customer_name, 
    os.o_orderkey, 
    os.total_revenue
FROM 
    nation_stats ns
JOIN 
    product_stats ps ON ns.supplier_count > 10
JOIN 
    order_summary os ON ns.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = os.o_orderkey))
ORDER BY 
    ns.supplier_count DESC, 
    os.total_revenue DESC
LIMIT 10;
