WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
TopNSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    s.s_name AS supplier_name,
    cs.total_spent,
    cs.order_count,
    (CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END) AS customer_value,
    (SELECT COUNT(*) FROM part p WHERE p.p_mfgr = 'ManufacturerA') AS manufacture_a_count,
    (SELECT AVG(l.l_discount) FROM lineitem l WHERE l.l_orderkey = r.o_orderkey AND l.l_returnflag = 'R') AS avg_return_discount
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerStats cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_phone = s.s_phone LIMIT 1)
WHERE 
    r.rank_order <= 5
    AND r.o_totalprice >= 1000
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;