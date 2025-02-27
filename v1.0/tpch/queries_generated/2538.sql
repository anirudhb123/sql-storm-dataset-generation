WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationSupplierStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
TopPartByRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_shipdate > DATE '2022-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_acct_balance,
    cps.total_orders,
    cps.total_spent,
    r.s_name AS top_supplier,
    r.s_acctbal AS top_supplier_balance
FROM 
    NationSupplierStats ns
LEFT JOIN 
    CustomerOrderStats cps ON TRUE
LEFT JOIN 
    RankedSuppliers r ON r.rank = 1
WHERE 
    ns.supplier_count > 5 AND
    (cps.total_spent IS NULL OR cps.total_spent > 1000)
ORDER BY 
    ns.n_name, cps.total_spent DESC;

