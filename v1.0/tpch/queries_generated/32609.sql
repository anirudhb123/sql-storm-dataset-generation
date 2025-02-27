WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.o_custkey,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
                        AND o.o_orderdate > oh.o_orderdate
    WHERE 
        o.o_orderstatus = 'O'
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity,
        MAX(l.l_tax) AS max_tax
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
HighestSpend AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSpend cs
),
TotalLineItems AS (
    SELECT 
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' AND l.l_linestatus = 'F'
)
SELECT 
    hs.c_name,
    hs.total_spent,
    l.total_sales,
    l.avg_quantity,
    l.max_tax,
    (SELECT total_lineitems FROM TotalLineItems) AS total_lineitems
FROM 
    HighestSpend hs
JOIN 
    LineItemSummary l ON hs.c_custkey IN (
        SELECT DISTINCT o.o_custkey 
        FROM orders o 
        JOIN lineitem li ON o.o_orderkey = li.l_orderkey
        WHERE li.l_extendedprice > 1000
    )
WHERE 
    hs.rank <= 10 AND hs.total_spent IS NOT NULL;
