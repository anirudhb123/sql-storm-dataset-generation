WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
LineItemTotals AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
),
RankedOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        co.o_totalprice,
        lit.total_price,
        ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY lit.total_price DESC) AS order_rank
    FROM 
        CustomerOrders co
    JOIN 
        LineItemTotals lit ON co.o_orderkey = lit.l_orderkey
)
SELECT 
    rp.s_name AS Supplier_Name,
    rp.p_name AS Part_Name,
    ro.c_name AS Customer_Name,
    ro.o_orderdate AS Order_Date,
    ro.total_price AS Total_Line_Item_Price,
    ro.o_totalprice AS Order_Total_Amount
FROM 
    SupplierParts rp
JOIN 
    RankedOrders ro ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rp.s_suppkey)
WHERE 
    ro.order_rank = 1
ORDER BY 
    rp.s_name, ro.c_name;
