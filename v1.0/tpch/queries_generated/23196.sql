WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O') 
        AND o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(c.total_orders, 0) AS total_orders,
        COALESCE(c.total_spent, 0.00) AS total_spent
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    CONCAT('Customer:', hvc.c_name) AS Customer_Info,
    NVL(hvc.total_orders, 0) AS Total_Orders,
    CASE
        WHEN hvc.total_spent > 10000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS Customer_Type,
    s.s_name AS Supplier_Name,
    p.p_name AS Part_Name,
    (SELECT COUNT(DISTINCT l.l_linenumber) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                            FROM orders o 
                            WHERE o.o_custkey = hvc.c_custkey)) AS line_items_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    supplier s ON hvc.c_custkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    hvc.total_orders IS NOT NULL
ORDER BY 
    hvc.total_spent DESC, 
    hvc.total_orders ASC 
LIMIT 10;
