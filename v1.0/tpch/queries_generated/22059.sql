WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
),
OrdersWithDiscount AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN l.l_discount IS NULL THEN o.o_totalprice 
            ELSE o.o_totalprice * (1 - l.l_discount) 
        END AS discounted_price,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
FinalReport AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(od.discounted_price), 0) AS total_spent,
        COUNT(od.o_orderkey) AS order_count,
        STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts
    FROM 
        customer c
    LEFT JOIN 
        OrdersWithDiscount od ON c.c_custkey = od.o_custkey
    LEFT JOIN 
        lineitem l ON od.o_orderkey = l.l_orderkey
    LEFT JOIN 
        PopularParts p ON l.l_partkey = p.p_partkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(f.c_custkey) AS customer_count,
    AVG(f.total_spent) AS avg_spent_per_customer,
    MAX(f.order_count) AS max_orders_per_customer
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    FinalReport f ON c.c_custkey = f.c_custkey
WHERE 
    EXISTS (
        SELECT 1 FROM RankedSuppliers rs 
        WHERE rs.s_suppkey = c.c_custkey 
        AND rs.rn = 1
    )
GROUP BY 
    r.r_name
ORDER BY 
    region_name;
