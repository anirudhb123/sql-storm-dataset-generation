WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s 
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
PartSupplier AS (
    SELECT
        ps.ps_partkey, 
        ps.ps_suppkey, 
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey, 
        n.n_name AS nation_name
    FROM customer c 
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN l.l_discount > 0.1 THEN 'Discounted'
        ELSE 'Regular Price'
    END AS price_status,
    RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS region_rank,
    cn.nation_name,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers s ON l.l_suppkey = s.s_suppkey AND s.rn = 1
JOIN CustomerNation cn ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey IN (SELECT c_custkey FROM HighValueCustomers)) 
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = l.l_orderkey)) 
GROUP BY 
    p.p_partkey,
    p.p_name,
    s.s_name,
    l.l_discount,
    cn.nation_name,
    r.r_regionkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 
    OR (SELECT COUNT(*) FROM HighValueCustomers) > 10 
ORDER BY region_rank, sales_status DESC;
