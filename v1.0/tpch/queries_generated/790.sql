WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O')
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
), CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name,
    p.p_type,
    COUNT(DISTINCT so.o_orderkey) AS total_orders,
    SUM(so.o_totalprice) AS total_revenue,
    AVG(cs.total_spent) AS avg_customer_spending,
    MAX(sd.total_supply_cost) AS max_supply_cost,
    CASE 
        WHEN AVG(cs.total_spent) IS NULL THEN 'No Orders'
        ELSE CAST(AVG(cs.total_spent) AS VARCHAR)
    END AS avg_spending_desc
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedOrders so ON so.o_orderkey = ps.ps_partkey
LEFT JOIN 
    CustomerSummary cs ON cs.total_orders > 0
GROUP BY 
    r.r_name, p.p_type
HAVING 
    COUNT(DISTINCT so.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
