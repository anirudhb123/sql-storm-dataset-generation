WITH RECURSIVE RegionSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 1000
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
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_earned,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.region_name,
    rs.s_name AS top_supplier,
    COALESCE(c.c_name, 'No Customers') AS customer_name,
    COALESCE(co.order_count, 0) AS customer_order_count,
    COALESCE(co.total_spent, 0.00) AS customer_total_spent,
    la.total_earned,
    la.avg_quantity,
    la.distinct_parts
FROM 
    RegionSupplier rs
FULL OUTER JOIN 
    CustomerOrders co ON rs.s_suppkey = (
        SELECT s_suppkey 
        FROM supplier 
        WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA') 
        ORDER BY s_acctbal DESC 
        LIMIT 1
    )
FULL OUTER JOIN 
    LineItemAnalysis la ON la.l_orderkey = (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_custkey = co.c_custkey 
        ORDER BY o_orderdate DESC 
        LIMIT 1
    )
WHERE 
    rs.rank = 1
    OR (co.customer_order_count > 0 AND la.total_earned IS NOT NULL)
ORDER BY 
    region_name, customer_name;
