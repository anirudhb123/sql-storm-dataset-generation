WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent IS NOT NULL AND c.total_spent > 1000
),
FinalResults AS (
    SELECT 
        r.r_name,
        hs.rank,
        c.c_name AS high_value_customer,
        c.total_spent,
        s.total_supplycost
    FROM 
        RankedSuppliers hs
    LEFT JOIN 
        nation n ON hs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        HighValueCustomers c ON c.customer_rank <= 10 AND c.total_spent < hs.total_supplycost
    WHERE 
        hs.total_supplycost IS NOT NULL
    ORDER BY 
        r.r_name, hs.rank
)
SELECT 
    r_name,
    high_value_customer,
    total_spent,
    total_supplycost
FROM 
    FinalResults
WHERE 
    (total_spent IS NOT NULL OR total_supplycost IS NOT NULL)
    AND (high_value_customer IS NOT NULL OR r_name NOT LIKE '%Bizarre%')
    AND EXISTS (SELECT 1 
                FROM lineitem l 
                WHERE l.l_extendedprice BETWEEN 0 AND total_supplycost)
ORDER BY 
    r_name, total_spent DESC;
