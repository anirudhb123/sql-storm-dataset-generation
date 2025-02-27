WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
), 
SupplierPartPricing AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    c.c_name AS Customer_Name,
    c_orders.o_orderkey AS Order_Key,
    c_orders.o_orderdate AS Order_Date,
    c_orders.net_revenue AS Net_Revenue,
    COALESCE(supp.s_name, 'No Supplier') AS Supplier_Name,
    COALESCE(sp.supp_cost, 0) AS Supply_Cost,
    CASE 
        WHEN c_orders.net_revenue > 1000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS Revenue_Category
FROM 
    CustomerOrders c_orders
LEFT JOIN 
    RankedSuppliers supp ON supp.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM SupplierPartPricing sp
        WHERE sp.ps_partkey IN (
            SELECT l.l_partkey
            FROM lineitem l
            WHERE l.l_orderkey = c_orders.o_orderkey
        )
    )
LEFT JOIN 
    SupplierPartPricing sp ON sp.ps_suppkey = supp.s_suppkey
WHERE 
    supp.acct_rank = 1
ORDER BY 
    c_orders.o_orderdate DESC,
    Net_Revenue DESC
LIMIT 100;
