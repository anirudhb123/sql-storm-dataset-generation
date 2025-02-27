WITH CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spending,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    cs.c_name,
    cs.total_spending,
    pd.p_name,
    pd.total_supply_cost,
    ss.s_name,
    ss.avg_acct_balance
FROM 
    CustomerStats cs
JOIN 
    lineitem l ON l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = cs.c_custkey
    )
JOIN 
    PartDetails pd ON pd.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = l.l_suppkey
WHERE 
    cs.spending_rank <= 10 
    AND pd.total_supply_cost IS NOT NULL
ORDER BY 
    cs.total_spending DESC, ss.avg_acct_balance DESC;
