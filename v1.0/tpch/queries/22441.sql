WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        REPLACE(p.p_comment, ' defective', '') AS clean_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 100 
        AND p.p_retailprice IS NOT NULL
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
QualifiedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        tc.total_spent
    FROM 
        customer c
    LEFT JOIN 
        TotalOrders tc ON c.c_custkey = tc.o_custkey
    WHERE 
        (c.c_acctbal IS NULL OR c.c_acctbal > 0) 
        AND (tc.total_spent IS NULL OR tc.total_spent > 10000)
),
UnusualLineItems AS (
    SELECT 
        l.l_orderkey, 
        COUNT(*) AS line_count, 
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE 0 END) AS discounted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < '1994-01-01' 
        AND l.l_returnflag = 'R'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    q.c_custkey, 
    q.c_name, 
    ps.ps_partkey, 
    ps.ps_availqty, 
    COALESCE(t.discounted_price, 0) AS total_discounted_price,
    RANK() OVER (PARTITION BY q.c_custkey ORDER BY ps.ps_availqty DESC) AS customer_rank
FROM 
    QualifiedCustomers q
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM FilteredParts p WHERE p.p_retailprice BETWEEN 50 AND 200)
LEFT JOIN 
    UnusualLineItems t ON t.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = q.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    EXISTS (SELECT 1 FROM RankedSuppliers r WHERE r.s_suppkey = ps.ps_suppkey AND r.rank = 1)
ORDER BY 
    q.c_custkey, total_discounted_price DESC, customer_rank;