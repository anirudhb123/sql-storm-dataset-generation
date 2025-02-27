WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        customer cust
    JOIN 
        CustomerSpend cs ON cust.c_custkey = cs.c_custkey
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(sp.total_availqty, 0) AS available_quantity,
    COALESCE(sp.total_supplycost, 0) AS total_supply_cost,
    rc.o_orderkey,
    rc.o_orderdate,
    rc.o_totalprice,
    tc.c_name AS customer_name,
    tc.customer_rank
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedOrders rc ON rc.o_orderkey = (SELECT l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey LIMIT 1)
LEFT JOIN 
    TopCustomers tc ON tc.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = rc.o_orderkey LIMIT 1)
WHERE 
    p.p_retailprice IS NOT NULL 
    AND (sp.total_availqty IS NULL OR sp.total_availqty >= 50)
ORDER BY 
    p.p_retailprice DESC, 
    tc.customer_rank ASC NULLS LAST
LIMIT 100;
