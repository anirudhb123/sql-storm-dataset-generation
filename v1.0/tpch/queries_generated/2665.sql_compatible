
WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'Asia'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent,
        COALESCE(co.order_count, 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > 10000
)
SELECT 
    r.r_name, 
    hs.p_name,
    hs.total_sales,
    hvc.c_name,
    hvc.total_spent,
    hvc.order_count
FROM 
    RankedSales hs
JOIN 
    HighValueCustomers hvc ON hs.p_partkey = hvc.c_custkey
LEFT JOIN 
    region r ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE s.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = hs.p_partkey 
            LIMIT 1
        )
    )
WHERE 
    hs.sales_rank <= 5
ORDER BY 
    hs.total_sales DESC, hvc.total_spent DESC;
