WITH Recursive_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal - 100, level + 1
    FROM supplier s
    JOIN Recursive_Supplier rs ON s.s_suppkey = rs.s_suppkey
    WHERE rs.s_acctbal - 100 > 0
),
Part_Suppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
Region_Nations AS (
    SELECT n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 100 AND o.o_orderstatus = 'O'
),
Discounted_LineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    r.n_name,
    COUNT(DISTINCT so.s_suppkey) AS supplier_count,
    SUM(pl.total_supply_cost) AS total_part_cost,
    COUNT(co.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(dl.discounted_price) > 10000 THEN 'High Value'
        WHEN SUM(dl.discounted_price) IS NULL THEN 'No Orders'
        ELSE 'Standard Value'
    END AS order_value_category,
    ROW_NUMBER() OVER (PARTITION BY r.n_name ORDER BY SUM(dl.discounted_price) DESC) AS rn
FROM 
    Customer_Orders co
JOIN 
    Region_Nations r ON r.n_name IN (SELECT DISTINCT n.n_name FROM nation n WHERE n.n_nationkey = co.o_orderkey % 10)
LEFT JOIN 
    Recursive_Supplier so ON so.s_suppkey = co.o_orderkey
JOIN 
    Part_Suppliers pl ON pl.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > ALL (SELECT ps1.ps_supplycost FROM partsupp ps1 WHERE ps1.ps_partkey = ps.ps_partkey AND ps1.ps_availqty IS NOT NULL))
LEFT JOIN 
    Discounted_LineItems dl ON dl.l_orderkey = co.o_orderkey
GROUP BY 
    c.c_name, r.n_name
HAVING 
    COUNT(DISTINCT so.s_suppkey) > 0 AND SUM(pl.total_supply_cost) IS NOT NULL
ORDER BY 
    r.n_name, order_count DESC, rn;
