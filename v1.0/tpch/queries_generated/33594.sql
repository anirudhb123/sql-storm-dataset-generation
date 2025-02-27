WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ps.ps_availqty, 
        0 AS level
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ps.ps_availqty, 
        sc.level + 1
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0 AND sc.level < 2
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY l.l_linenumber ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredSupply AS (
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        AVG(sc.s_acctbal) AS avg_acct_balance
    FROM 
        SupplyChain sc
    GROUP BY 
        sc.s_suppkey, sc.s_name
)
SELECT 
    p.p_name, 
    f.s_name, 
    f.avg_acct_balance,
    a.total_revenue,
    a.order_count
FROM 
    part p
LEFT JOIN 
    FilteredSupply f ON p.p_partkey = f.s_suppkey
LEFT JOIN 
    AggregatedOrders a ON a.o_orderkey = (SELECT o.o_orderkey
                                            FROM orders o
                                            WHERE o.o_orderkey = a.o_orderkey AND a.rnk <= 5
                                            ORDER BY o.o_orderdate DESC
                                            LIMIT 1)
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 10;
