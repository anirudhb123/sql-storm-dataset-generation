WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS supplies_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
BestCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
SalesSummary AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    p.p_name,
    r.r_name,
    COALESCE(B.total_spent, 0) AS customer_expenditure,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(ss.total_supplycost) AS total_supplier_costs,
    COUNT(ls.l_orderkey) AS order_count,
    AVG(rso.o_totalprice) AS avg_order_price
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders rso ON l.l_orderkey = rso.o_orderkey
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN 
    BestCustomers B ON B.c_custkey = (SELECT c.c_custkey 
                                        FROM customer c 
                                        WHERE c.c_nationkey = 
                                              (SELECT n.n_nationkey 
                                               FROM nation n 
                                               WHERE n.n_regionkey = (SELECT r.r_regionkey 
                                                                       FROM region r 
                                                                       WHERE r.r_name = 'ASIA') 
                                              LIMIT 1)
                                        LIMIT 1)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(ss.total_supplycost) IS NOT NULL
ORDER BY 
    COALESCE(customer_expenditure, 0) DESC, 
    p.p_name;
