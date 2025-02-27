WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_partkey = p.p_partkey)
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 0
       AND SUM(o.o_totalprice) IS NOT NULL
),
FinalReport AS (
    SELECT 
        ns.n_name AS nation_name,
        ps.p_name AS most_expensive_part,
        cs.c_name AS customer_name,
        cs.order_count,
        cs.total_spent
    FROM 
        NationStats ns
    CROSS JOIN 
        (SELECT * FROM RankedParts WHERE rank = 1) ps
    INNER JOIN 
        CustomerOrders cs ON ns.supplier_count = cs.order_count
    WHERE 
        ns.total_acctbal BETWEEN (SELECT AVG(total_acctbal) FROM NationStats) AND (SELECT MAX(total_acctbal) FROM NationStats)
        AND LENGTH(ps.p_name) > 10
        AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey) AND l.l_returnflag = 'R')
)
SELECT 
    fr.nation_name,
    fr.most_expensive_part,
    fr.customer_name,
    fr.order_count,
    fr.total_spent
FROM 
    FinalReport fr
WHERE 
    fr.total_spent IS NOT NULL
ORDER BY 
    fr.total_spent DESC, fr.nation_name ASC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM FinalReport) / 2;
