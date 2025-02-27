WITH TotalSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        RANK() OVER (ORDER BY COALESCE(ts.total_revenue, 0) DESC) AS revenue_rank
    FROM part p
    LEFT JOIN TotalSales ts ON p.p_partkey = ts.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    rp.total_revenue,
    rp.revenue_rank,
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent
FROM RankedParts rp
FULL OUTER JOIN CustomerOrders co ON rp.total_revenue > 1000 AND co.total_spent > 5000
WHERE rp.revenue_rank <= 10 OR co.order_count IS NOT NULL
ORDER BY rp.revenue_rank, co.total_spent DESC;
