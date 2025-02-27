WITH RECURSIVE Part_Supplier AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rn
    FROM partsupp
    WHERE ps_availqty IS NOT NULL
),
Aggregated_Supplier AS (
    SELECT ps_partkey, 
           SUM(ps_availqty) AS total_avail_qty,
           AVG(ps_supplycost) AS avg_supply_cost
    FROM Part_Supplier
    WHERE rn <= 5
    GROUP BY ps_partkey
),
Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2021-01-01'
),
Order_Summary AS (
    SELECT co.c_custkey, SUM(co.o_totalprice) AS total_order_value
    FROM Customer_Orders co
    GROUP BY co.c_custkey
),
Region_Nation AS (
    SELECT r.r_name AS region_name, n.n_name AS nation_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 3
),
Final_Output AS (
    SELECT ps.p_partkey, AVG(ps.p_retailprice) AS avg_retail_price,
           SUM(ao.total_order_value) AS total_customer_spending,
           rn.supplier_count
    FROM part ps
    LEFT JOIN Aggregated_Supplier AS asu ON ps.p_partkey = asu.ps_partkey
    LEFT JOIN Order_Summary AS ao ON ao.c_custkey IN (
        SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL
    )
    LEFT JOIN Region_Nation AS rn ON rn.nation_name = (
        SELECT n.n_name FROM nation n WHERE n.n_nationkey = (
            SELECT MIN(n_nationkey) FROM nation
            GROUP BY n_name
        )
    )
    GROUP BY ps.p_partkey, rn.supplier_count
    HAVING AVG(ps.p_retailprice) IS NOT NULL
       AND SUM(ao.total_order_value) IS NOT NULL
       AND rn.supplier_count >= 2
)
SELECT DISTINCT f.p_partkey, f.avg_retail_price, f.total_customer_spending, f.supplier_count
FROM Final_Output f
WHERE (f.total_customer_spending IS NULL OR f.total_customer_spending > 
       COALESCE((SELECT MAX(total_customer_spending) FROM Final_Output), 0) / 10)
       AND f.supplier_count = (SELECT MAX(supplier_count) FROM Final_Output)
ORDER BY f.avg_retail_price DESC
LIMIT 100;
