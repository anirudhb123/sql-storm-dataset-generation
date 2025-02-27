WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal * 0.9, ch.c_nationkey, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_nationkey = c.c_nationkey
    WHERE ch.level < 3 AND c.custkey != ch.c_custkey
),

AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),

FilteredSales AS (
    SELECT *,
        CASE 
            WHEN order_count IS NULL THEN 'No Orders'
            WHEN order_count > 10 THEN 'Lots of Orders'
            ELSE 'Few Orders' 
        END AS order_description
    FROM AggregatedData
    WHERE total_sales > 5000
)

SELECT 
    ph.nation_name,
    COALESCE(AVG(c.c_acctbal), 0) AS avg_account_balance,
    fs.total_sales,
    fs.order_description,
    ph.sales_rank
FROM FilteredSales fs
RIGHT JOIN CustomerHierarchy c ON fs.nation_name = c.c_nationkey
LEFT JOIN (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
) ph ON fs.nation_name = ph.nation_name
GROUP BY ph.nation_name, fs.total_sales, fs.order_description, ph.sales_rank
HAVING COUNT(DISTINCT c.c_custkey) > 1 OR COUNT(DISTINCT fs.total_sales) IS NULL
ORDER BY total_sales DESC, avg_account_balance DESC
LIMIT 25 OFFSET 5;
