WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSpend AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    C.c_name,
    COALESCE(S.total_supply_cost, 0) AS supplier_cost,
    COALESCE(O.o_orderstatus, 'N/A') AS order_status,
    CASE 
        WHEN C.total_spent IS NULL THEN 'No Orders'
        WHEN C.total_spent > 1000 THEN 'High Roller'
        ELSE 'Regular Customer' 
    END AS customer_type,
    CASE 
        WHEN O.o_orderstatus = 'O' AND O.rn <= 10 THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_classification
FROM 
    CustomerSpend C
LEFT JOIN 
    RankedOrders O ON C.c_custkey = O.o_orderkey
LEFT JOIN 
    SupplierInfo S ON C.c_custkey = S.s_suppkey
WHERE 
    C.c_custkey IN (
        SELECT c_custkey 
        FROM customer 
        WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
    )
    AND (O.o_orderstatus IS NULL OR O.o_orderstatus != 'F')
ORDER BY 
    supplier_cost DESC, customer_type;
