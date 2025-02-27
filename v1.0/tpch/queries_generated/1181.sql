WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
ProductSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ns.n_name AS nation, 
    SUM(COALESCE(r.total_supply_cost, 0)) AS total_supply_cost_by_nation,
    COUNT(DISTINCT h.c_custkey) AS high_value_customers_count,
    COALESCE(SUM(ps.total_sales), 0) AS total_product_sales,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_sold
FROM nation ns
LEFT JOIN RankedSuppliers r ON ns.n_nationkey = r.s_nationkey AND r.rank <= 3
LEFT JOIN HighValueCustomers h ON ns.n_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = h.c_custkey)
LEFT JOIN ProductSales ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderstatus = 'O')
WHERE ns.n_name IS NOT NULL
GROUP BY ns.n_name
ORDER BY total_supply_cost_by_nation DESC, high_value_customers_count DESC;
