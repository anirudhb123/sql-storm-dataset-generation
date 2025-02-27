WITH RECURSIVE NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT ns.n_nationkey, ns.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM NationSupplier ns
    JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > ns.s_acctbal * 0.9
),
PartSupplies AS (
    SELECT ps.ps_partkey, p.p_name, s.s_name AS supplier_name, ps.ps_availqty, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, p.p_name, s.s_name, ps.ps_availqty
),
RankedSupplies AS (
    SELECT p.p_name, ps.supplier_name, ps.total_revenue, 
           RANK() OVER (PARTITION BY p.p_name ORDER BY ps.total_revenue DESC) AS rank
    FROM PartSupplies ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT ns.n_name, r.p_name, r.supplier_name, r.total_revenue
FROM NationSupplier ns
JOIN RankedSupplies r ON ns.s_suppkey = r.supplier_name
WHERE r.rank = 1 AND ns.n_name IS NOT NULL
ORDER BY ns.n_name, r.total_revenue DESC;
