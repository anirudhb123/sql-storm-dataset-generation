WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
),
TopRevenueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.total_revenue, 
        ROW_NUMBER() OVER (ORDER BY p.total_revenue DESC) AS revenue_rank
    FROM 
        FilteredParts p
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    c.c_name AS customer_name, 
    t.p_name AS top_part, 
    COALESCE(s.total_availqty, 0) AS supplier_availqty,
    COALESCE(s.total_supplycost, 0) AS supplier_cost
FROM 
    RankedOrders o
LEFT JOIN 
    TopRevenueParts t ON o.o_orderkey = t.p_partkey
LEFT JOIN 
    SupplierPartDetails s ON t.p_partkey = s.ps_partkey
WHERE 
    o.order_rank <= 5
ORDER BY 
    o.o_orderdate, o.o_orderkey;
