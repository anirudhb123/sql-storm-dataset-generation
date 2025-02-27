WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_totalprice IS NOT NULL
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 100
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
    COUNT(DISTINCT TOPCUSTOMERS.c_custkey) AS num_top_customers,
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_acctbal, ')'), ', ') AS suppliers
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN TopCustomers AS TOPCUSTOMERS ON s.s_nationkey = TOPCUSTOMERS.c_nationkey
GROUP BY p.p_partkey, p.p_name
HAVING SUM(l.l_quantity) IS NOT NULL AND (COUNT(DISTINCT l.l_orderkey) > 5 OR SUM(l.l_discount) < 0.2)
ORDER BY total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
