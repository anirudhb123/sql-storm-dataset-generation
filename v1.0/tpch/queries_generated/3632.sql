WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name
    FROM 
        SupplierPerformance sp
    WHERE 
        sp.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierPerformance)
),
TopCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_spent,
        ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary cus
)
SELECT 
    tc.c_name,
    tc.total_spent,
    hs.s_name AS supplier_name,
    sp.total_supply_value
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    HighValueSuppliers hs ON EXISTS (
        SELECT 1
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE l.l_suppkey = hs.s_suppkey AND o.o_custkey = tc.c_custkey
    )
JOIN 
    SupplierPerformance sp ON hs.s_suppkey = sp.s_suppkey
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC, hs.s_name;
