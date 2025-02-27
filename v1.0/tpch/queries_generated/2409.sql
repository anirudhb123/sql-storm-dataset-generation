WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    ss.total_supply_cost,
    cs.total_spent,
    ls.net_revenue,
    RANK() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS rank_order,
    COALESCE(ss.avg_acct_balance, 0) AS average_account_balance,
    COUNT(DISTINCT ls.line_count) OVER (PARTITION BY cs.c_custkey) AS distinct_line_items
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.order_count > 0
LEFT JOIN 
    LineItemStats ls ON cs.c_custkey = ls.l_orderkey
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    cs.total_spent DESC, rank_order;
