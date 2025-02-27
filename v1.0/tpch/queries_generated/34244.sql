WITH RECURSIVE region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey),
        SUM(s.s_acctbal) 
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE r.r_regionkey IS NOT NULL
    GROUP BY r.r_regionkey, r.r_name
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
supplier_profit AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) 
         FROM lineitem l 
         WHERE l.l_partkey = p.p_partkey) AS total_revenue
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    rs.r_name,
    cs.c_name,
    sp.p_name,
    sp.total_revenue - sp.total_cost AS profit,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    CASE 
        WHEN profit > 0 THEN 'Profitable'
        WHEN profit < 0 THEN 'Unprofitable'
        ELSE 'Break-even'
    END AS profitability,
    rs.nation_count,
    rs.total_supplier_balance
FROM region_summary rs
JOIN customer_summary cs ON rs.nation_count > 1
JOIN supplier_profit sp ON cs.rank <= 5
WHERE rs.total_supplier_balance IS NOT NULL
ORDER BY profit DESC, rs.r_name, cs.c_name;
