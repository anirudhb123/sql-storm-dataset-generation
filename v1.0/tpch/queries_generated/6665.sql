WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
TopSellers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name, 
    tp.p_brand AS top_brand, 
    COUNT(DISTINCT cs.c_custkey) AS total_customers, 
    SUM(cs.total_spent) AS total_sales,
    COUNT(DISTINCT ts.s_suppkey) AS total_suppliers,
    AVG(ts.total_sales) AS avg_sales_per_supplier
FROM 
    nation n
JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
JOIN 
    CustomerOrders cs ON cs.c_custkey = cs.c_custkey
JOIN 
    RankedParts tp ON tp.price_rank <= 5
JOIN 
    TopSellers ts ON ts.total_sales > 100000
WHERE 
    cs.total_spent > 500
GROUP BY 
    n.n_name, tp.p_brand
ORDER BY 
    total_sales DESC, total_customers DESC;
