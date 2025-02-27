WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    COALESCE(cos.total_orders, 0) AS total_orders,
    COALESCE(cos.total_spent, 0) AS total_spent,
    COALESCE(spi.total_available, 0) AS total_available,
    COALESCE(spi.total_cost, 0) AS total_cost,
    COUNT(ro.o_orderkey) AS rank_counts 
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer_order_summary cos ON cos.c_custkey = n.n_nationkey
LEFT JOIN 
    supplier_part_info spi ON spi.s_suppkey = n.n_nationkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = cos.total_orders
WHERE 
    n.n_nationkey IS NOT NULL
    AND (spi.total_cost IS NULL OR spi.total_cost > 100) 
    AND r.r_name LIKE 'E%'
GROUP BY 
    n.n_name, r.r_name, p.p_name, s.s_name, cos.total_orders, cos.total_spent, spi.total_available, spi.total_cost
ORDER BY 
    n.n_name, r.r_name;
