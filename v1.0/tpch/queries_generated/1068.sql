WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    sd.s_name AS supplier_name,
    cp.c_name AS customer_name,
    cp.total_spent,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No purchases' 
        ELSE 'Purchased' 
    END AS purchase_status
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierDetails sd ON r.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN 
    CustomerPurchases cp ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
WHERE 
    r.order_rank <= 5
  AND 
    (sd.total_available IS NOT NULL OR cp.total_spent IS NOT NULL)
ORDER BY 
    r.o_totalprice DESC, r.o_orderdate ASC;
