WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
AggregateOrderValues AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        a.total_spent,
        a.order_count,
        RANK() OVER (ORDER BY a.total_spent DESC) AS rank
    FROM 
        customer c
    JOIN 
        AggregateOrderValues a ON c.c_custkey = a.o_custkey
    WHERE 
        a.total_spent > 5000
)

SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    r.r_name AS region,
    ts.rank,
    ts.order_count,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rn = 1
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = rs.s_suppkey LIMIT 1)
JOIN 
    TopCustomers ts ON ts.c_custkey = (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = p.p_partkey LIMIT 1)
WHERE 
    p.p_retailprice > 25.00
ORDER BY 
    p.p_brand, ts.total_spent DESC;
