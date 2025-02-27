WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank_spent
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary cs ON c.c_custkey = cs.o_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    AVG(cs.c_acctbal) AS avg_account_balance,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(cs.rank_spent) AS highest_rank_spent,
    STRING_AGG(DISTINCT s.s_name, ', ') FILTER (WHERE rs.rn = 1) AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey 
LEFT JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
WHERE 
    cs.c_acctbal IS NOT NULL 
    AND (cs.c_comment LIKE '%important%' OR cs.c_mktsegment = 'HOUSEHOLD')
GROUP BY 
    r.r_name
ORDER BY 
    avg_account_balance DESC, customer_count DESC;
