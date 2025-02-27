WITH DiscountedSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS discounted_price
    FROM 
        lineitem
    WHERE 
        l_shipdate > DATE '1997-01-01'
    GROUP BY 
        l_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ds.discounted_price) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        DiscountedSales ds ON o.o_orderkey = ds.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        AVG(s.avg_cost) AS avg_supplier_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierStats s ON n.n_nationkey = s.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tc.c_name AS customer_name,
    rs.r_name AS region_name,
    rs.total_nations,
    tc.total_spent,
    ss.total_available,
    ss.avg_cost
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
JOIN 
    nation n ON n.n_nationkey = (SELECT n_nationkey FROM customer WHERE c_custkey = tc.c_custkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RegionStats rs ON r.r_regionkey = rs.r_regionkey
JOIN 
    SupplierStats ss ON ss.s_suppkey = (SELECT ps_suppkey FROM partsupp LIMIT 1)
ORDER BY 
    tc.total_spent DESC;