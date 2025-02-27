WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
HighValueLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPartInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, MAX(ps.ps_availqty) AS max_avail_qty
    FROM partsupp ps
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    oi.total_price AS order_total_price,
    COALESCE(r.r_name, 'Unknown') AS region,
    CASE 
        WHEN r.r_regionkey IS NULL THEN 'No Region'
        ELSE r.r_name 
    END AS safe_region,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY oi.order_total_price DESC) AS order_rank
FROM CustomerOrders oi
LEFT JOIN RankedSuppliers s ON oi.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey IN (
        SELECT ps.ps_partkey 
        FROM SupplierPartInfo ps 
        WHERE ps.ps_suppkey = s.s_suppkey
    )
)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
INNER JOIN SupplierPartInfo p ON p.ps_suppkey = s.s_suppkey
WHERE oi.o_orderkey IN (SELECT l.l_orderkey FROM HighValueLineItems l)
ORDER BY oi.total_price DESC, customer_name;
