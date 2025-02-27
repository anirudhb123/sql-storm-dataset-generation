WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2023-10-01'
    GROUP BY 
        r.r_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_order_value,
        co.order_count,
        ROW_NUMBER() OVER (ORDER BY co.total_order_value DESC) AS rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
)
SELECT 
    r.region_name,
    rc.c_name,
    rc.total_order_value,
    rc.order_count,
    CASE 
        WHEN rc.total_order_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    RegionalSales r
FULL OUTER JOIN 
    RankedCustomers rc ON r.region_name = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = rc.c_custkey))
WHERE 
    r.total_sales > 10000 OR rc.order_count IS NOT NULL
ORDER BY 
    r.region_name, rc.total_order_value DESC;
