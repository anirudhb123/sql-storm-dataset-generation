WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
OrderPayments AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_payment
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND 
        (o.o_orderstatus IS NULL OR o.o_orderstatus <> 'F')
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    HAVING 
        SUM(l.l_discount) <= 0.10
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS cus_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_mktsegment NOT IN ('AUTOMOBILE', 'FURNITURE')
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    AVG(COALESCE(o.total_payment, 0)) AS avg_order_value,
    SUM(CASE WHEN hs.rank <= 5 THEN hs.total_supply_cost ELSE 0 END) AS sum_top_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    OrderPayments o ON o.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_orderstatus = 'O'
    )
JOIN 
    RankedSuppliers hs ON hs.rank <= 5 AND hs.s_nationkey = n.n_nationkey
WHERE 
    r.r_comment LIKE '%beautiful%'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    region_name;
