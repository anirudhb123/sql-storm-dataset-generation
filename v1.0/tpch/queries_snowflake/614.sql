WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_price
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.o_custkey
    WHERE 
        co.rn <= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name AS region_name,
    sc.total_supply_cost,
    tc.c_custkey,
    tc.c_name,
    tc.total_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierCost sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    region r ON r.r_regionkey = (
        SELECT n.n_regionkey
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey = ps.ps_suppkey
        LIMIT 1
    )
FULL OUTER JOIN 
    TopCustomers tc ON tc.total_price > 10000
WHERE 
    (sc.total_supply_cost IS NOT NULL OR tc.c_custkey IS NOT NULL)
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
ORDER BY 
    p.p_partkey, tc.total_price DESC;
