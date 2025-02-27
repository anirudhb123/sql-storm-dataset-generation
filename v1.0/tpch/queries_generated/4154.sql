WITH NationSummary AS (
    SELECT n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_balance,
           AVG(s.s_acctbal) AS avg_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
TopCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) 
                                    FROM orders o2 
                                    WHERE o2.o_orderstatus = 'O')
),
CustomerRanked AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT ps.ps_partkey,
           s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
)
SELECT ns.n_name, 
       ns.supplier_count, 
       ns.total_balance, 
       ns.avg_balance, 
       COALESCE(crc.total_spent, 0) AS total_spent_by_top_customer,
       crc.rank,
       sp.total_available
FROM NationSummary ns
LEFT JOIN CustomerRanked crc ON ns.supplier_count > 0 
                             AND ns.total_balance > (SELECT AVG(ns2.total_balance) 
                                                      FROM NationSummary ns2)
LEFT JOIN SupplierParts sp ON ns.supplier_count = (SELECT COUNT(*) 
                                                   FROM supplier s2 
                                                   WHERE s2.s_nationkey = ns.n_nationkey)
ORDER BY ns.supplier_count DESC, total_spent_by_top_customer DESC;
