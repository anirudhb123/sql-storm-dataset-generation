
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rnk
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_nationkey = c.c_nationkey
        )
    AND c.c_name IS NOT NULL
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 1000
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        COUNT(l.l_orderkey) > 5
),
CustomerNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS Nation_Name,
    COUNT(DISTINCT r.r_regionkey) AS Region_Count,
    SUM(COALESCE(c.total_acctbal, 0)) AS Total_Customer_Balance,
    AVG(sp.total_availqty) AS Avg_Availability_Per_Supplier,
    COUNT(DISTINCT o.o_orderkey) AS Total_High_Value_Orders
FROM 
    region r
LEFT JOIN 
    CustomerNation c ON r.r_name LIKE '%' || c.n_name || '%'  
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2 
            WHERE p2.p_container LIKE 'MED%' 
        )
    )
LEFT JOIN 
    HighValueOrders o ON o.o_orderkey IN (
        SELECT o2.o_orderkey 
        FROM orders o2 
        WHERE o2.o_orderstatus = 'O' 
        AND o2.o_orderdate BETWEEN DATE '1993-01-01' AND DATE '1993-12-31'
    )
WHERE 
    r.r_comment IS NOT NULL OR r.r_comment LIKE '%excellent%'
GROUP BY 
    r.r_name
ORDER BY 
    Total_Customer_Balance DESC, Nation_Name
LIMIT 10 OFFSET (SELECT COUNT(*) FROM nation) / 2;
