WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL 
        AND c.c_acctbal > 5000
)
SELECT 
    n.n_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(c.c_acctbal) AS max_acctbal,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice END) AS max_fulfilled_order
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    n.n_name, p.p_name
HAVING 
    total_revenue > 10000 
ORDER BY 
    total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
