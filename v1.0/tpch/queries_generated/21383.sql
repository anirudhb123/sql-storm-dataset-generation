WITH RegionalStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
CustomerSavings AS (
    SELECT 
        co.c_custkey,
        co.total_spent,
        SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * l.l_discount ELSE 0 END) AS total_savings
    FROM 
        CustomerOrders co
    JOIN 
        lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
    GROUP BY 
        co.c_custkey, co.total_spent
)
SELECT 
    rs.region_name,
    cs.c_custkey,
    cs.total_spent,
    COALESCE(cs.total_savings, 0) AS savings,
    RANK() OVER (PARTITION BY rs.region_name ORDER BY COALESCE(cs.total_savings, 0) DESC) AS savings_rank
FROM 
    RegionalStats rs
JOIN 
    CustomerSavings cs ON (rs.total_acctbal > (SELECT AVG(total_acctbal) FROM RegionalStats) OR rs.nation_count IS NULL)
WHERE 
    (cs.total_spent > 1000 AND cs.total_spent < 5000)
    OR (cs.total_spent >= 5000 AND (SELECT COUNT(*) FROM CustomerOrders WHERE order_count > 10) > 5)
ORDER BY 
    rs.region_name, savings_rank;
