WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_per_order
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
FilteredProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 0
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
NationStat AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        AVG(c.total_spent) AS avg_spent_per_cust,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    ns.avg_spent_per_cust,
    ns.customer_count,
    COALESCE(SUM(fp.supplier_count), 0) AS total_suppliers,
    CASE 
        WHEN ns.customer_count > 10 THEN 'High'
        WHEN ns.customer_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment
FROM 
    NationStat ns
LEFT JOIN 
    FilteredProducts fp ON ns.customer_count = fp.supplier_count
LEFT JOIN 
    RankedSales rs ON rs.l_suppkey = fp.p_partkey
GROUP BY 
    n.n_name, ns.avg_spent_per_cust, ns.customer_count
ORDER BY 
    customer_segment DESC, avg_spent_per_cust DESC;
