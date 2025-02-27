WITH PriceSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        CTE_RANKS.rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN (
        SELECT 
            o_orderkey, 
            ROW_NUMBER() OVER (PARTITION BY o_orderkey ORDER BY l_linenumber DESC) AS rn
        FROM 
            lineitem
    ) CTE_RANKS ON o.o_orderkey = CTE_RANKS.o_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, CTE_RANKS.rn
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_supply_cost,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    COUNT(DISTINCT od.o_orderkey) AS order_count,
    MAX(od.total_revenue) AS max_revenue,
    SUM(CASE 
        WHEN od.total_revenue > 0 THEN od.total_revenue 
        ELSE NULL 
    END) AS positive_revenue_sum
FROM 
    part p
LEFT JOIN 
    PriceSummary ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    OrderDetails od ON p.p_partkey = od.o_orderkey 
LEFT JOIN 
    CustomerSummary cs ON cs.total_spent > 0
GROUP BY 
    p.p_partkey, p.p_name, ps.total_supply_cost, cs.total_spent
ORDER BY 
    total_supply_cost DESC, customer_spending DESC;
