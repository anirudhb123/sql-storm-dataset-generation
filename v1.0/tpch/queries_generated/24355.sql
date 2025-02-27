WITH RECURSIVE CustOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus,
           o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate < CURRENT_DATE
    UNION ALL
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderstatus,
           o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY o.o_orderdate DESC)
    FROM CustOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate < CURRENT_DATE
      AND co.order_rank < 5
      AND o.o_orderstatus = (SELECT DISTINCT o2.o_orderstatus FROM orders o2 WHERE o2.o_orderkey = co.o_orderkey)
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_cost,
        SUM(CASE WHEN p.p_size IS NULL THEN 0 ELSE p.p_size END) as total_size
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL OR s.s_comment IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
),
FilteredNations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = n.n_nationkey AND s.s_acctbal > 100.00)
      AND n.n_name NOT LIKE '%land'
      AND LENGTH(n.n_comment) > 50
),
FinalQuery AS (
    SELECT co.c_name, t.total_amount, sd.s_name, fn.n_name,
           RANK() OVER (PARTITION BY co.c_custkey ORDER BY t.total_amount DESC) as sales_rank
    FROM CustOrders co 
    JOIN TotalSales t ON co.o_orderkey = t.l_orderkey
    JOIN SupplierDetails sd ON sd.total_cost > 0
    JOIN FilteredNations fn ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 10)
    WHERE co.order_rank <= 3
)
SELECT DISTINCT f.c_name, f.total_amount, f.s_name, f.n_name
FROM FinalQuery f
WHERE f.sales_rank <= (SELECT AVG(sales_rank) FROM FinalQuery)
  AND (f.total_amount IS NOT NULL OR f.total_amount > 1000)
ORDER BY f.total_amount DESC, f.c_name ASC;
