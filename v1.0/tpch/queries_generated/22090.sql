WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        AVG(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
OrderCustomerInfo AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    r.n_name AS Nation,
    COUNT(DISTINCT o.orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    MAX(s.s_acctbal) AS Highest_Acct_Balance,
    STRING_AGG(DISTINCT c.c_name) AS Customer_Names
FROM 
    HighValueOrders h
JOIN 
    lineitem l ON h.o_orderkey = l.l_orderkey
JOIN 
    OrderCustomerInfo o ON h.o_orderkey = o.o_orderkey
JOIN 
    RankedSuppliers s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierAvailability sa ON l.l_partkey = sa.ps_partkey AND l.l_suppkey = sa.ps_suppkey
WHERE 
    n.n_name IS NOT NULL
    AND s.rnk < 5
    AND sa.max_avail_qty IS NOT NULL
GROUP BY 
    r.n_name
ORDER BY 
    Total_Sales DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

