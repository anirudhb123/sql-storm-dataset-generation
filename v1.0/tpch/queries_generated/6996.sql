WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PerformanceBenchmark AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        t.o_orderkey,
        t.o_totalprice,
        s.total_supply_cost,
        s.unique_parts
    FROM 
        customer c
    JOIN 
        TopOrders t ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = t.o_orderkey)
    JOIN 
        SupplierStats s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey = t.o_orderkey LIMIT 1)
)
SELECT 
    p.r_name AS region_name,
    SUM(pb.o_totalprice) AS total_order_value,
    AVG(pb.total_supply_cost) AS average_supply_cost,
    COUNT(DISTINCT pb.c_name) AS customer_count
FROM 
    PerformanceBenchmark pb
JOIN 
    customer c ON pb.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region p ON n.n_regionkey = p.r_regionkey
GROUP BY 
    p.r_name
ORDER BY 
    total_order_value DESC;
