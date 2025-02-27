WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price,
        COUNT(*) OVER (PARTITION BY o.o_orderstatus) AS total_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank_price <= 10
),
CustomerSummaries AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    hs.o_orderkey,
    hs.o_orderdate,
    hs.o_totalprice,
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    cs.order_count
FROM 
    HighValueOrders hs
JOIN 
    CustomerSummaries cs ON hs.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = cs.c_custkey
    )
JOIN 
    lineitem li ON hs.o_orderkey = li.l_orderkey
WHERE 
    li.l_returnflag = 'N'
ORDER BY 
    hs.o_orderdate DESC, hs.o_totalprice DESC
LIMIT 100;
