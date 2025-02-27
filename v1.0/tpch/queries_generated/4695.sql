WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2023-12-31'
),
OrderLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_returnflag
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
AggregatedSales AS (
    SELECT o.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM CustomerOrders o
    JOIN OrderLineItems l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.c_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.s_name,
    np.n_name,
    SUM(sp.ps_availqty) AS total_avail_qty,
    COALESCE(SUM(as.total_sales), 0) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY np.n_name ORDER BY SUM(sp.ps_availqty) DESC) AS rank
FROM SupplierParts sp
LEFT JOIN NationRegion np ON EXISTS (
    SELECT 1 
    FROM supplier s 
    WHERE s.s_suppkey = sp.s_suppkey AND s.s_nationkey = np.n_nationkey
)
LEFT JOIN AggregatedSales as ON as.c_custkey = sp.s_suppkey
GROUP BY sr.s_name, np.n_name
HAVING total_avail_qty > 10
ORDER BY np.n_name, total_sales DESC;
