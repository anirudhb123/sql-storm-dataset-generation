WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_size, p_retailprice, p_comment, 0 AS level
    FROM part
    WHERE p_size < 10
    
    UNION ALL
    
    SELECT p.partkey, p.p_name, p.p_mfgr, p.p_size, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p_size = ph.p_size + 1
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
FinalSummary AS (
    SELECT 
        p.p_name,
        COALESCE(SC.total_cost, 0) AS part_total_cost,
        ND.total_balance AS nation_balance,
        COS.order_count,
        COS.total_spent,
        NTILE(4) OVER (ORDER BY COS.total_spent DESC) AS spending_quartile,
        CASE 
            WHEN COS.total_spent IS NULL THEN 'No Orders'
            WHEN COS.total_spent < 1000 THEN 'Low'
            WHEN COS.total_spent BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS spending_category
    FROM part p
    LEFT JOIN SupplierCost SC ON p.p_partkey = SC.ps_partkey
    LEFT JOIN NationDetails ND ON p.p_mfgr = ND.n_nationkey
    LEFT JOIN CustomerOrderSummary COS ON p.p_partkey = COS.c_custkey
)
SELECT f.*, 
       ROW_NUMBER() OVER (PARTITION BY f.spending_category ORDER BY f.part_total_cost DESC) AS rank
FROM FinalSummary f
WHERE f.nation_balance IS NOT NULL
ORDER BY f.spending_category, f.part_total_cost DESC;
