WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY c.c_custkey, c.c_name
    UNION ALL
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_sales + (SELECT COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0)
                          FROM partsupp ps 
                          JOIN part p ON ps.ps_partkey = p.p_partkey
                          WHERE p.p_retailprice > 100) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_sales DESC) AS rank
    FROM CustomerSales cs
    WHERE cs.rank = 1
),
SignificantRegions AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
    HAVING COUNT(DISTINCT n.n_nationkey) > 5
)
SELECT 
    cs.c_name,
    SUM(cs.total_sales) AS total_sales,
    sr.nation_count,
    CASE 
        WHEN SUM(cs.total_sales) > 10000 THEN 'High'
        WHEN SUM(cs.total_sales) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM CustomerSales cs
JOIN SignificantRegions sr ON cs.c_custkey IN (SELECT c.c_custkey
                                                  FROM customer c 
                                                  WHERE c.c_nationkey IN (SELECT n.n_nationkey
                                                                          FROM nation n
                                                                          JOIN region r ON n.n_regionkey = r.r_regionkey
                                                                          WHERE r.r_regionkey IS NULL))
GROUP BY cs.c_name, sr.nation_count
ORDER BY total_sales DESC
LIMIT 10 OFFSET (SELECT COUNT(*) 
                 FROM CustomerSales) / 2;
