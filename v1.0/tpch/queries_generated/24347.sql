WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CAST(s.s_name AS varchar(100)) AS path
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, CONCAT(sh.path, ' -> ', sp.s_name)
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_suppkey
    WHERE sp.s_acctbal IS NOT NULL
), 

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

PartSupplies AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

HighValueCustomers AS (
    SELECT cust.c_custkey, cust.c_name, cust.total_spent
    FROM CustomerOrders cust
    WHERE cust.total_spent > 10000
)

SELECT
    ns.n_nationkey,
    ns.n_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returns,
    AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY s.s_name ORDER BY l.l_shipdate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS avg_price,
    MAX(CASE WHEN s.s_acctbal IS NULL THEN 'No Account Balance' ELSE 'Account Balance' END) AS acct_status,
    ph.path AS supplier_hierarchy
FROM
    nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN PartSupplies ps ON ps.p_partkey = l.l_partkey
LEFT JOIN HighValueCustomers hv ON hv.c_custkey = l.l_orderkey 
WHERE
    ns.n_name LIKE '%land%'
    AND (ps.total_supply_cost IS NOT NULL OR l.l_shipdate IS NULL)
GROUP BY 
    ns.n_nationkey, 
    ns.n_name, 
    s.s_suppkey, 
    ph.path
HAVING 
    SUM(l.l_quantity) > 50 
ORDER BY 
    total_returns DESC, 
    avg_price DESC
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
