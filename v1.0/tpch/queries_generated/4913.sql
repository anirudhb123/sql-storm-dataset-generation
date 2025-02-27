WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
), SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    rv.o_orderkey,
    rv.o_orderdate,
    rv.o_orderstatus,
    sp.p_name,
    sp.s_name AS supplier_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    COALESCE(c.total_spent, 0) AS total_spent_by_customer,
    CASE 
        WHEN rv.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status_label
FROM 
    RankedOrders rv
LEFT JOIN 
    HighValueCustomers c ON rv.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    lineitem l ON rv.o_orderkey = l.l_orderkey
JOIN 
    SupplierPartDetails sp ON l.l_partkey = sp.ps_partkey
WHERE 
    rv.rank_order = 1
AND 
    sp.ps_supplycost < 50.00
ORDER BY 
    rv.o_orderdate DESC, total_spent_by_customer DESC;
