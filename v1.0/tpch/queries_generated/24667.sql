WITH RECURSIVE Price_Rank AS (
    SELECT 
        ps.partkey, 
        ps.suppkey, 
        ps.ps_supplycost, 
        RANK() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost DESC) as cost_rank
    FROM 
        partsupp ps
)
, National_Supplier AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
, Customer_Orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    ns.n_name AS supplier_nation,
    ns.supplier_count,
    ns.avg_acctbal,
    co.total_spent,
    co.order_count,
    COUNT(l.l_orderkey) AS lineitem_count,
    CASE 
        WHEN AVG(l.l_discount) IS NULL THEN 'No Discounts'
        ELSE CAST(AVG(l.l_discount) AS VARCHAR)
    END AS avg_discount,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
FROM 
    part p
LEFT JOIN 
    Price_Rank pr ON p.p_partkey = pr.partkey AND pr.cost_rank = 1
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    National_Supplier ns ON ps.ps_suppkey = ns.n_nationkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    Customer_Orders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1)
WHERE 
    p.p_size > 10 
    AND p.p_retailprice BETWEEN 50.00 AND 200.00
    AND EXISTS (SELECT 1 FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey AND s.s_acctbal > (SELECT avg(s2.s_acctbal) FROM supplier s2))
GROUP BY 
    p.p_partkey, ns.n_name, co.c_custkey
ORDER BY 
    ns.avg_acctbal DESC, co.total_spent DESC;
