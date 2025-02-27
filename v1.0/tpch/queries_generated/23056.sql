WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) >= 5
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        l.l_returnflag,
        COUNT(*) OVER (PARTITION BY l.l_orderkey) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        l.l_orderkey, l.l_returnflag
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(ss.supplier_count, 0) AS supplier_count,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    f.net_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY f.net_revenue DESC) AS revenue_rank,
    (CASE 
        WHEN f.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END) AS return_status
FROM 
    RankedParts p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_nationkey)
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey LIMIT 1))
LEFT JOIN 
    FilteredLineItems f ON f.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = f.l_orderkey)
ORDER BY 
    p.p_partkey, revenue_rank DESC;
