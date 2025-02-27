WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -3, GETDATE()) 
        AND o.o_orderstatus IN ('O', 'F')
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        STRING_AGG(s.s_comment, '; ') AS combined_comment
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COUNT(DISTINCT l.l_orderkey) AS total_line_items
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    co.c_name,
    co.total_spent,
    ro.o_orderkey,
    ro.o_orderdate,
    CASE 
        WHEN ro.order_rank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_type,
    s.combined_comment,
    CASE 
        WHEN COALESCE(co.total_orders, 0) = 0 THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status
FROM 
    CustomerOrderDetails co
FULL OUTER JOIN 
    RankedOrders ro ON co.total_orders > 0 AND ro.o_orderkey < 50000
LEFT JOIN 
    SuppliersWithComments s ON co.c_custkey = s.s_suppkey
WHERE 
    (co.total_spent > 1000 OR s.part_count IS NULL)
ORDER BY 
    co.total_spent DESC, ro.o_orderdate DESC
OPTION (MAXDOP 1);
