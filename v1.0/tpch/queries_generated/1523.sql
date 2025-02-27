WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
SupplierProfit AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)) - SUM(ps.ps_supplycost * l.l_quantity), 0) AS profit
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-07-01' AND DATE '2023-09-30'
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(c.total_spent, 0) AS customer_total_spent,
    COALESCE(p.profit, 0) AS supplier_profit,
    r.rank
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrders c ON r.o_orderkey = c.c_custkey
LEFT JOIN 
    SupplierProfit p ON p.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                         WHERE l.l_orderkey = r.o_orderkey 
                                         LIMIT 1)
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
