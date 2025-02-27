WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(od.total_order_value) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(co.total_spent) AS total_region_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_regionkey
)

SELECT 
    r.r_name,
    COALESCE(rs.total_region_sales, 0) AS total_sales,
    COALESCE(SUM(ss.total_supply_value), 0) AS total_supply_value,
    COUNT(DISTINCT co.c_custkey) AS customer_count
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_nationkey
LEFT JOIN 
    SupplierStats ss ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_nationkey = ss.s_nationkey
    )
LEFT JOIN 
    CustomerOrders co ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN customer c ON n.n_nationkey = c.c_nationkey
        WHERE c.c_custkey = co.c_custkey
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC, total_supply_value DESC
LIMIT 10;
