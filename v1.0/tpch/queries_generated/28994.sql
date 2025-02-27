WITH PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
           SUM(l.l_quantity) AS total_ordered,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
),
RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
           AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT pd.p_brand, pd.p_type, count(*) AS distinct_suppliers, 
       AVG(ss.avg_account_balance) AS avg_sup_acc_balance,
       SUM(pd.total_ordered) AS sum_total_ordered,
       SUM(pd.total_returned) AS sum_total_returned,
       COUNT(DISTINCT rn.n_nationkey) AS distinct_nations
FROM PartDetails pd
JOIN SupplierStats ss ON pd.p_partkey IN (SELECT ps.ps_partkey 
                                           FROM partsupp ps 
                                           WHERE ps.ps_suppkey IN (SELECT s.s_suppkey 
                                                                   FROM supplier s))
JOIN RegionNation rn ON rn.n_nationkey IN (SELECT s.s_nationkey 
                                             FROM supplier s 
                                             WHERE s.s_suppkey IN (SELECT ps.ps_suppkey 
                                                                   FROM partsupp ps 
                                                                   WHERE ps.ps_partkey = pd.p_partkey))
WHERE pd.total_ordered > 0
GROUP BY pd.p_brand, pd.p_type
ORDER BY avg_sup_acc_balance DESC, sum_total_ordered DESC;
