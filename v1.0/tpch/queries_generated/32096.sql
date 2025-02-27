WITH RECURSIVE SalesRank CTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
), SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
), NationalStatistics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    n.n_name AS Nation,
    COALESCE(s.cust_name, 'No Orders') AS Customer_Name,
    COALESCE(CASE WHEN sr.rank_within_nation <= 3 THEN sr.total_spent ELSE NULL END, 0) AS Top_Spent,
    s.p_name AS Part_Name,
    s.ps_supplycost AS Supply_Cost,
    ns.customer_count,
    ns.total_sales
FROM NationalStatistics ns
LEFT JOIN SalesRank sr ON ns.n_nationkey = sr.c_custkey
LEFT JOIN SupplierPartDetails s ON s.supplier_rank <= 3
WHERE ns.total_sales IS NOT NULL
ORDER BY ns.n_name, Top_Spent DESC, Supply_Cost ASC
LIMIT 100;
