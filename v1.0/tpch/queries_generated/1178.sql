WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS acct_balance_rank
    FROM 
        customer c
)
SELECT 
    COALESCE(r.o_orderkey, 0) AS order_key,
    COALESCE(r.total_revenue, 0) AS revenue,
    COALESCE(s.part_count, 0) AS supplier_part_count,
    c.c_name AS customer_name,
    c.acct_balance_rank
FROM 
    RankedOrders r
FULL OUTER JOIN 
    SupplierDetails s ON s.part_count > 10
JOIN 
    CustomerInfo c ON c.acct_balance_rank <= 10
WHERE 
    r.revenue_rank <= 5 OR s.total_supply_cost > 1000.00
ORDER BY 
    revenue DESC, supplier_part_count DESC;
