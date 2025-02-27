WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate <= DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        total_revenue > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT COALESCE(s.rank, 0)) AS supplier_count,
    AVG(co.total_spent) AS average_customer_spent,
    MAX(hvo.total_revenue) AS max_order_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    supplier_count DESC, average_customer_spent DESC;
