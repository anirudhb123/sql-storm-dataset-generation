WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(ps.ps_availqty) > 0
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
),
LateShipments AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_shipdate, l.l_commitdate, l.l_receiptdate,
           CASE 
               WHEN l.l_shipdate > l.l_commitdate THEN 'Delayed'
               WHEN l.l_receiptdate IS NULL THEN 'In Transit'
               ELSE 'On Time'
           END AS shipment_status
    FROM lineitem l
)

SELECT ns.n_name, 
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(CASE WHEN hs.total_cost IS NOT NULL THEN hs.total_cost ELSE 0 END) AS total_high_value_cost,
       SUM(s.s_acctbal) AS total_supplier_balance,
       STRING_AGG(DISTINCT CASE WHEN lsh.shipment_status = 'Delayed' THEN 'Delayed Shipment' ELSE 'No Delay' END, ', ') AS shipment_summary
FROM nation ns
LEFT JOIN RankedSuppliers s ON ns.n_nationkey = s.s_nationkey AND s.rnk <= 3
LEFT JOIN CustomerOrders co ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
LEFT JOIN HighValueParts hs ON hs.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey)
LEFT JOIN LateShipments lsh ON lsh.l_orderkey = co.o_orderkey
GROUP BY ns.n_name
HAVING COUNT(DISTINCT co.o_orderkey) > 10 OR SUM(s.s_acctbal) IS NULL
ORDER BY total_orders DESC NULLS LAST;
