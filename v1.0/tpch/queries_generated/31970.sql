WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
    WHERE o.o_orderdate > oh.o_orderdate
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING SUM(ps.ps_availqty) > 50 AND AVG(ps.ps_supplycost) < 20
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    oh.level,
    p.p_name,
    c.c_name,
    CASE 
        WHEN l.l_discount > 0.1 THEN 'Discounted'
        ELSE 'Regular'
    END AS price_category,
    COALESCE(p.total_avail_qty, 0) AS available_quantity,
    COALESCE(RANK() OVER (ORDER BY o.o_totalprice DESC), 0) AS order_rank
FROM OrderHierarchy oh
JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN FilteredParts p ON l.l_partkey = p.p_partkey
JOIN RankedCustomers c ON oh.o_custkey = c.c_custkey
WHERE l.l_shipdate BETWEEN '2023-02-01' AND '2023-12-31'
AND c.rank <= 10
ORDER BY o.o_orderdate, c.c_name, o.o_orderkey;
