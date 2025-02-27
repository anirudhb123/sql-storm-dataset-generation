WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name AS part_name,
    ns.n_name AS supplier_nation,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    ss.unique_parts_supplied,
    ss.total_supply_cost,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY COALESCE(cs.total_spent, 0) DESC) AS rank_by_spending,
    CASE 
        WHEN ns.n_name IS NULL THEN 'Unknown Nation'
        ELSE ns.n_name
    END AS nation_label
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN CustomerOrders cs ON cs.c_custkey = (SELECT c.c_custkey 
                                                FROM customer c 
                                                WHERE c.c_name LIKE '%' || p.p_comment || '%' 
                                                LIMIT 1)
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE p.p_size IN (SELECT DISTINCT ps1.ps_availqty * 2
                   FROM partsupp ps1 
                   WHERE ps1.ps_availqty > 0)
   AND (s.s_acctbal IS NULL OR s.s_acctbal > 500.00)
   AND (p.p_retailprice BETWEEN 10 AND 1000)
ORDER BY rank_by_spending, part_name;
