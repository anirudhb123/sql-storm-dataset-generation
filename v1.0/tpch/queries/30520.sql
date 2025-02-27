WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderTotals AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_profit
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    sh.s_name AS supplier_name,
    pd.p_name AS part_name,
    ot.o_orderkey,
    ot.net_profit,
    rc.c_name AS customer_name,
    rc.total_spent
FROM SupplierHierarchy sh
FULL OUTER JOIN PartDetails pd ON sh.s_suppkey = pd.p_partkey
JOIN OrderTotals ot ON pd.p_partkey = ot.o_orderkey
JOIN RankedCustomers rc ON ot.o_orderkey = rc.c_custkey
WHERE rc.rnk <= 10 AND pd.total_cost IS NOT NULL
ORDER BY sh.s_name, pd.p_name;
