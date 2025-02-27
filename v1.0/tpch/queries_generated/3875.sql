WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        SupplierInfo s
    WHERE 
        s.rnk <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineItem AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sold_amount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
),
TopPartSellers AS (
    SELECT 
        pli.l_partkey, 
        SUM(pli.sold_amount) AS total_sold
    FROM 
        OrderLineItem pli
    GROUP BY 
        pli.l_partkey
)
SELECT 
    n.n_name AS nation_name,
    ts.s_name AS supplier_name,
    ts.s_acctbal AS supplier_account_balance,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    tps.total_sold,
    (CASE 
        WHEN co.total_spent IS NULL THEN 0 
        ELSE co.total_spent / NULLIF(co.order_count, 0) 
     END) AS avg_spent_per_order 
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.s_nationkey = n.n_nationkey
JOIN 
    customer co ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                     FROM partsupp ps 
                                     WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                             FROM part p 
                                                             WHERE p.p_size > 20)
                                     LIMIT 1)
LEFT JOIN 
    TopPartSellers tps ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                            FROM partsupp ps 
                                            WHERE ps.ps_partkey = tps.l_partkey 
                                            LIMIT 1)
WHERE 
    ts.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
ORDER BY 
    n.n_name, ts.s_name;
