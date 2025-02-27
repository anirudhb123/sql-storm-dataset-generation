WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_nationkey,
        c.c_name,
        co.order_count,
        co.total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.rnk <= 5
    UNION ALL
    SELECT 
        c.c_nationkey,
        c.c_name,
        co.order_count,
        co.total_spent
    FROM 
        TopCustomers tc
    JOIN 
        customer c ON tc.c_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders co ON co.c_custkey = c.c_custkey
    WHERE 
        tc.total_spent < co.total_spent
        AND NOT EXISTS (
            SELECT 1 FROM TopCustomers tc2 WHERE tc2.c_name = c.c_name
        )
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
NationRanked AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ROW_NUMBER() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    nc.n_name AS Nation,
    tc.c_name AS Top_Customer,
    tc.order_count AS Order_Count,
    tc.total_spent AS Total_Spent,
    COALESCE(ss.total_supply_cost, 0) AS Total_Supply_Cost,
    nr.nation_rank AS Nation_Rank
FROM 
    TopCustomers tc
JOIN 
    region r ON tc.c_nationkey = r.r_regionkey
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o
            WHERE o.o_custkey = tc.c_custkey
        )
        LIMIT 1
    )
JOIN 
    NationRanked nr ON tc.c_nationkey = nr.n_nationkey
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    Total_Spent DESC, 
    Order_Count ASC;
