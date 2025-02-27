WITH 
    RankedSuppliers AS (
        SELECT 
            s.s_suppkey, 
            s.s_name, 
            s.s_acctbal,
            RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
        FROM 
            supplier s
    ),
    ExpensiveParts AS (
        SELECT 
            p.p_partkey, 
            p.p_name,
            p.p_retailprice,
            p.p_comment,
            ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rn
        FROM 
            part p 
        WHERE 
            p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
            AND LENGTH(p.p_comment) > 10
    ),
    OrderDetails AS (
        SELECT 
            o.o_custkey,
            COUNT(DISTINCT l.l_orderkey) AS order_count,
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY 
            o.o_custkey
    )
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END), 0) AS total_returned,
    COUNT(DISTINCT os.o_custkey) AS unique_customers,
    AVG(der.total_revenue) AS avg_revenue,
    ps.ps_availqty,
    ps.ps_supplycost
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey 
LEFT JOIN 
    OrderDetails der ON rs.s_suppkey = der.o_custkey
LEFT JOIN 
    (SELECT 
         ps_partkey, 
         ps_availqty, 
         ps_supplycost 
     FROM 
         partsupp 
     WHERE 
         ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp) 
         AND ps_availqty IS NOT NULL) ps ON rs.s_suppkey = ps.ps_suppkey 
RIGHT JOIN 
    ExpensiveParts ep ON ep.p_partkey = ps.ps_partkey
WHERE 
    ep.rn <= 5 
GROUP BY 
    n.n_name, ps.ps_availqty, ps.ps_supplycost
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_returned DESC, unique_customers ASC, nation_name;
