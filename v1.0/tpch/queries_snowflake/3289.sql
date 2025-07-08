
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR, o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
HighValueOrders AS (
    SELECT 
        RO.o_orderkey,
        RO.o_orderdate,
        RO.revenue,
        COALESCE(c.c_name, 'Unknown') AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(MONTH, RO.o_orderdate) ORDER BY RO.revenue DESC) AS customer_month_rank
    FROM 
        RankedOrders RO
    LEFT JOIN 
        customer c ON c.c_custkey = (
            SELECT 
                c1.c_custkey 
            FROM 
                customer c1 
            WHERE 
                c1.c_custkey = (
                    SELECT 
                        o.o_custkey 
                    FROM 
                        orders o 
                    WHERE 
                        o.o_orderkey = RO.o_orderkey
                )
        )
    WHERE 
        RO.order_rank <= 10
)
SELECT 
    HVO.o_orderkey,
    HVO.o_orderdate,
    HVO.revenue,
    HVO.customer_name,
    CASE 
        WHEN HVO.customer_month_rank IS NULL THEN 'No Customer'
        ELSE 'Customer Ranked'
    END AS customer_status
FROM 
    HighValueOrders HVO
LEFT JOIN 
    supplier s ON s.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (
                SELECT 
                    l.l_partkey 
                FROM 
                    lineitem l 
                WHERE 
                    l.l_orderkey = HVO.o_orderkey
            )
        LIMIT 1
    )
WHERE 
    HVO.revenue > (SELECT AVG(revenue) FROM RankedOrders)
ORDER BY 
    HVO.o_orderdate DESC, HVO.revenue DESC;
