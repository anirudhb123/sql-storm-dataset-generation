WITH RECURSIVE PriceHierarchy AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        0 AS level
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100

    UNION ALL

    SELECT 
        pp.p_partkey,
        pp.p_name,
        pp.p_retailprice,
        ph.level + 1
    FROM 
        part pp
    JOIN 
        PriceHierarchy ph ON pp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < ph.p_retailprice ORDER BY ps.ps_supplycost DESC LIMIT 1)
)

SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS account_balance,
    p.p_name AS part_name,
    SUM(li.l_quantity) AS total_quantity,
    AVG(li.l_discount) AS average_discount,
    CASE 
        WHEN SUM(li.l_extendedprice) IS NULL THEN 0
        ELSE SUM(li.l_extendedprice) 
    END AS total_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(li.l_extendedprice) DESC) AS rank_within_nation
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    PriceHierarchy ph ON li.l_partkey = ph.p_partkey
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal, p.p_name
HAVING 
    SUM(li.l_quantity) > 50
ORDER BY 
    rank_within_nation, total_extended_price DESC;

WITH TotalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY 
        n.n_name
)

SELECT 
    r.r_name AS region_name,
    COALESCE(TOTAL.total_sales, 0) AS total_sales
FROM 
    region r
LEFT JOIN 
    (SELECT r.r_regionkey, SUM(ts.total_sales) AS total_sales 
     FROM TotalSales ts
     JOIN nation n ON ts.nation_name = n.n_name
     JOIN region r ON n.n_regionkey = r.r_regionkey 
     GROUP BY r.r_regionkey) AS TOTAL ON r.r_regionkey = TOTAL.r_regionkey
ORDER BY 
    total_sales DESC;
