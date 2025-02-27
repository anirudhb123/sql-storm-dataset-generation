WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), CTE_Nation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        ROW_NUMBER() OVER (ORDER BY n.n_name) AS row_num
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
      AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ps.total_cost,
    CASE 
        WHEN p.rnk <= 5 THEN 'Top Brand'
        ELSE 'Other'
    END AS ranking_label,
    n.n_name AS nation_name,
    SUM(COALESCE(fo.net_price, 0)) AS order_total
FROM RankedParts p
LEFT JOIN SupplierStats ps ON p.p_partkey = ps.part_count
LEFT JOIN CTE_Nation n ON ps.s_suppkey = n.row_num
LEFT JOIN FilteredOrders fo ON fo.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
GROUP BY p.p_partkey, p.p_name, p.p_brand, ps.total_cost, ranking_label, n.n_name
HAVING COUNT(DISTINCT p.p_partkey) < 10
ORDER BY p.p_brand, p.p_retailprice DESC
FETCH FIRST 100 ROWS ONLY;
