WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           COUNT(ps.ps_supplycost) OVER (PARTITION BY n.n_nationkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
AvailableParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           SUM(ps.ps_availqty) AS total_avail
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(ps.ps_availqty) IS NOT NULL
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           LAG(o.o_totalprice) OVER (ORDER BY o.o_orderdate) AS previous_order,
           LEAD(o.o_orderstatus) OVER (ORDER BY o.o_orderdate) AS next_status
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
InvoiceSummaries AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_invoice
    FROM lineitem li
    WHERE li.l_returnflag = 'N'
    GROUP BY li.l_orderkey
)
SELECT 
    s.s_name, 
    r.r_name,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN rank = 1 THEN s.s_suppkey END) AS top_suppliers,
    COALESCE(MAX(fs.previous_order), 0) AS last_high_order_price,
    COALESCE(MAX(fs.next_status), 'N/A') AS following_order_status
FROM RankedSuppliers s
JOIN region r ON s.rank <= 3 AND s.s_suppkey = s.s_suppkey
LEFT JOIN AvailableParts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN FilteredOrders fs ON fs.o_orderkey IN (SELECT li.l_orderkey FROM lineitem li WHERE li.l_suppkey = s.s_suppkey)
LEFT JOIN InvoiceSummaries inv ON inv.l_orderkey = fs.o_orderkey
GROUP BY s.s_name, r.r_name
HAVING SUM(ps.ps_supplycost) IS NOT NULL AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY r.r_name ASC, total_supply_cost DESC;
