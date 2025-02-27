WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 10000 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 5000 AND 10000 THEN 'Moderate'
            ELSE 'Cheap' 
        END as price_category
    FROM part p
    WHERE p.p_size IS NOT NULL
),
AggregateOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierNotInNation AS (
    SELECT 
        DISTINCT s.s_suppkey
    FROM supplier s
    WHERE s.s_nationkey NOT IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')
),
TotalCostByCategory AS (
    SELECT 
        p.price_category, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM HighValueParts p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY p.price_category
),
OrderDateSummary AS (
    SELECT
        DATE_TRUNC('month', o.o_orderdate) AS order_month,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2023-01-01'
    GROUP BY order_month
)
SELECT 
    ns.s_suppkey,
    ns.s_name, 
    ns.s_acctbal,
    tc.total_cost,
    od.order_month,
    od.order_count,
    od.avg_price
FROM RankedSuppliers ns
LEFT JOIN TotalCostByCategory tc ON ns.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN HighValueParts hp ON ps.ps_partkey = hp.p_partkey 
    WHERE hp.price_category = 'Expensive' 
    LIMIT 1
) OR ns.s_suppkey IN (SELECT s.s_suppkey FROM SupplierNotInNation)
FULL OUTER JOIN OrderDateSummary od ON od.order_month IS NOT NULL
WHERE ns.rank = 1 AND 
      (ns.s_acctbal IS NULL OR ns.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)) 
ORDER BY ns.s_name 
FETCH FIRST 10 ROWS ONLY;
