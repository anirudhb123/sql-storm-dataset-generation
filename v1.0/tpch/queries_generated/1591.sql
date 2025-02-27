WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
SuppliersPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000.00
),
TotalOrderCost AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_cost
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        COALESCE(SUM(to.total_order_cost), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        TotalOrderCost to ON o.o_orderkey = to.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    SUM(ps.total_cost) AS total_supply_cost,
    SUM(cs.total_spent) AS total_customer_spending
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SuppliersPartInfo ps ON s.s_suppkey = ps.s_suppkey
LEFT JOIN 
    CustomerSummary cs ON cs.order_count > 0
GROUP BY 
    r.r_name
HAVING 
    SUM(cs.total_spent) > 50000
ORDER BY 
    total_supply_cost DESC, total_customer_spending DESC;
