WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_orders + 1,
        co.total_spent + ol.l_extendedprice
    FROM 
        CustomerOrders co
    JOIN 
        lineitem ol ON ol.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey) 
    WHERE 
        ol.l_returnflag = 'R' AND 
        ol.l_linestatus = 'O'
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
),
ProductAvailability AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT co.c_custkey) AS distinct_customers,
    AVG(co.total_spent) AS avg_spent,
    SUM(pa.total_available) AS total_availability,
    (SELECT COUNT(*) FROM RankedSuppliers rs WHERE rs.ranking <= 5) AS top_suppliers_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    ProductAvailability pa ON pa.p_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 0 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT co.c_custkey) > 10
ORDER BY 
    avg_spent DESC;
