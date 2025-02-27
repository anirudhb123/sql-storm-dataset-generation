WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS TotalAvailableQty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
), 
OrderSummary AS (
    SELECT 
        co.c_custkey,
        co.o_orderkey,
        co.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalOrderValue
    FROM 
        CustomerOrders co
    JOIN 
        lineitem li ON co.o_orderkey = li.l_orderkey
    WHERE 
        co.OrderRank <= 5 AND co.o_orderstatus = 'O' -- only consider top 5 recent orders
    GROUP BY 
        co.c_custkey, co.o_orderkey, co.o_orderdate
)

SELECT 
    co.c_name AS CustomerName,
    co.o_orderkey AS OrderKey,
    co.o_orderdate AS OrderDate,
    os.TotalOrderValue AS OrderValue,
    sp.p_name AS PartName,
    sp.TotalAvailableQty,
    CASE 
        WHEN os.TotalOrderValue IS NULL THEN 'No orders'
        ELSE 'Order exists'
    END AS OrderExists,
    CONCAT('Total Order Value: $', COALESCE(os.TotalOrderValue, 0)) AS OrderValueString
FROM 
    CustomerOrders co
LEFT JOIN 
    OrderSummary os ON co.c_custkey = os.c_custkey AND co.o_orderkey = os.o_orderkey
LEFT JOIN 
    SupplierPartInfo sp ON sp.TotalAvailableQty > 0
WHERE 
    co.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' -- filter for the current year
ORDER BY 
    co.c_name, co.o_orderdate DESC;
