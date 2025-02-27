WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
           o.o_totalprice,
           c.c_mktsegment,
           n.n_name AS nation_name,
           r.r_name AS region_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE order_rank = 1
),
SupplierPrice AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) IS NOT NULL
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           COUNT(l.l_linenumber) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
           AVG(l.l_tax) AS avg_tax
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    TO_CHAR(TOP.o_orderdate, 'YYYY-MM-DD') AS formatted_orderdate,
    TOP.o_totalprice AS max_order_price,
    L.line_count AS total_line_items,
    L.total_line_price,
    SP.total_supplycost,
    CASE 
        WHEN SP.total_supplycost IS NULL THEN 'No Supplier' 
        ELSE 'Regular Supplier' 
    END AS supplier_status,
    SUBSTRING(TOP.nation_name, 1, 3) || '-' || 
    REPLACE(TOP.region_name, ' ', '_') AS sector_identifier
FROM TopOrders TOP
LEFT JOIN LineItemStats L ON TOP.o_orderkey = L.l_orderkey
FULL OUTER JOIN SupplierPrice SP ON L.l_orderkey = (SELECT l_orderkey 
                                                      FROM lineitem 
                                                      WHERE l_partkey = SP.ps_partkey 
                                                      LIMIT 1) 
WHERE TOP.o_totalprice > COALESCE((SELECT AVG(o_totalprice) FROM orders), 0)
ORDER BY TOP.o_orderdate DESC, SP.total_supplycost ASC
LIMIT 50;
