WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier AS s
    LEFT JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrderStats AS cos
)
SELECT 
    tc.c_name AS Top_Customer,
    s.s_name AS Supplier,
    ps.p_name AS Part_Name,
    ps.p_retailprice AS Retail_Price,
    COALESCE(pss.total_availability, 0) AS Availability,
    (ps.p_retailprice * COALESCE(pss.total_availability, 0)) AS Potential_Revenue
FROM 
    TopCustomers AS tc
INNER JOIN 
    orders AS o ON tc.c_custkey = o.o_custkey
INNER JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
INNER JOIN 
    partsupp AS psu ON l.l_partkey = psu.ps_partkey
INNER JOIN 
    supplier AS s ON psu.ps_suppkey = s.s_suppkey
INNER JOIN 
    part AS ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    SupplierPartStats AS pss ON s.s_suppkey = pss.s_suppkey
WHERE 
    tc.rank <= 10
    AND (l.l_discount > 0.1 OR l.l_discount IS NULL)
ORDER BY 
    Potential_Revenue DESC;
