WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        r.r_name AS region_name
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.total_spent,
        cust.total_orders
    FROM 
        CustomerSummary cust
    WHERE 
        cust.total_spent > (
            SELECT AVG(total_spent) 
            FROM CustomerSummary
        )
)
SELECT 
    s.s_name,
    s.region_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown' 
    END AS order_status,
    COALESCE(cust.total_spent, 0) AS customer_total_spent,
    COALESCE(cust.total_orders, 0) AS customer_total_orders
FROM 
    RankedOrders o
FULL OUTER JOIN 
    SupplierDetails s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
        WHERE li.l_orderkey = o.o_orderkey 
        LIMIT 1
    )
LEFT JOIN 
    HighValueCustomers cust ON cust.c_custkey = o.o_orderkey
WHERE 
    s.s_acctbal > 1000.00
ORDER BY 
    o.o_orderdate DESC, 
    s.s_name ASC;