WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_mktsegment LIKE 'B%' 
        AND o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderdate
),
RankedCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY total_spent DESC) AS rank_spent
    FROM 
        CustomerOrders c
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT rc.custkey) AS total_customers,
    SUM(rc.total_orders) AS total_orders,
    AVG(rc.total_spent) AS avg_spent
FROM 
    RankedCustomers rc
JOIN 
    supplier s ON rc.custkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rc.rank_spent <= 5
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_customers DESC;
