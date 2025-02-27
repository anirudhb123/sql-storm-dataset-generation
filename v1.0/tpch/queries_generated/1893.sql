WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
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
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.order_count,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS spend_rank
    FROM 
        CustomerOrders c
)
SELECT 
    rs.region_name,
    rc.c_name,
    rc.total_spent,
    rc.order_count,
    COALESCE(rc.spend_rank, 'No Orders') AS spend_rank
FROM 
    RegionSales rs
FULL OUTER JOIN 
    RankedCustomers rc ON rs.region_name = (
        SELECT r.r_name
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = rc.c_custkey
        LIMIT 1
    )
ORDER BY 
    rs.total_sales DESC NULLS LAST, rc.spend_rank;
