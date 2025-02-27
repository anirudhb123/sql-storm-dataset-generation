WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price,
           SUM(l.l_discount) OVER (PARTITION BY o.o_orderkey) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
), 
SupplierStats AS (
    SELECT s.s_suppkey,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(*) FILTER (WHERE s.s_acctbal < 0) AS negative_accounts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           LEAD(SUM(o.o_totalprice)) OVER (ORDER BY SUM(o.o_totalprice)) AS next_customer_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT DISTINCT 
    p.p_partkey,
    p.p_name,
    COALESCE(rn.rank_price, 0) AS order_rank,
    ss.total_parts,
    ss.avg_supply_cost,
    COALESCE(c.total_spent, 0) AS total_spent_customer,
    ss.negative_accounts
FROM part p
LEFT JOIN RankedOrders rn ON p.p_partkey = rn.o_orderkey
LEFT JOIN SupplierStats ss ON ss.total_parts > 5
LEFT JOIN CustomerOrders c ON c.order_count > 10
WHERE COALESCE(ss.avg_supply_cost, 0) > (
    SELECT AVG(ps_supplycost) 
    FROM partsupp 
    WHERE ps_supplycost IS NOT NULL
) AND (p.p_size BETWEEN 10 AND 30 OR p.p_name LIKE '%Widget%')
ORDER BY p.p_partkey DESC
LIMIT 100 OFFSET 50;
