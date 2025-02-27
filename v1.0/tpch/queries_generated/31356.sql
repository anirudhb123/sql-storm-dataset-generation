WITH RECURSIVE OrderDetail AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_acctbal DESC
    LIMIT 5
),
CustomerSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_retailprice,
    COALESCE(ts.total_acctbal, 0) AS top_nation_acctbal,
    cs.customer_total,
    ROW_NUMBER() OVER (PARTITION BY pd.p_partkey ORDER BY cs.customer_total DESC) AS sales_rank
FROM 
    part pd
LEFT JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopNations ts ON ts.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey))
LEFT JOIN 
    CustomerSales cs ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey LIMIT 1))
WHERE 
    pd.p_size > 10
ORDER BY 
    pd.p_partkey, sales_rank DESC;
