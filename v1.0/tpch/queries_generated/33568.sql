WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE oh.depth < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c1.c_acctbal) FROM customer c1
    )
),
AggregatedSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    COALESCE(sd.total_avail_qty, 0) AS supplier_avail_qty,
    COALESCE(hvc.c_name, 'N/A') AS high_value_customer,
    as.net_sales,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_qty,
    ROW_NUMBER() OVER (PARTITION BY hvc.c_mktsegment ORDER BY oh.o_totalprice DESC) AS rank
FROM OrderHierarchy oh
LEFT JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
LEFT JOIN HighValueCustomers hvc ON oh.o_custkey = hvc.c_custkey
LEFT JOIN AggregatedSales as ON oh.o_orderkey = as.l_orderkey
WHERE oh.o_totalprice > (
    SELECT AVG(o.o_totalprice) FROM orders o
)
AND l.l_shipdate IS NOT NULL
GROUP BY oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, sd.total_avail_qty, hvc.c_name, as.net_sales
ORDER BY oh.o_orderdate DESC
FETCH FIRST 100 ROWS ONLY;
