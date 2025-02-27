WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P')
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
        AND oh.order_level < 10
)
, CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(SUM(o.o_totalprice)) OVER (PARTITION BY c.c_nationkey) AS avg_spent_per_nation
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 1
)
, NestedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_supply_cost > 20000
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS latest_order_rank,
    ps.ps_supplycost,
    nn.n_name AS nation_name,
    CASE 
        WHEN o.o_totalprice IS NULL THEN 'No Price'
        WHEN o.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_category
FROM 
    CustomerSummary c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
    AND ps.ps_suppkey IN (SELECT s.s_suppkey FROM NestedSupplier s)
JOIN 
    nation nn ON c.c_nationkey = nn.n_nationkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    c.c_name, latest_order_rank DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
