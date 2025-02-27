WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        cs.total_spent
    FROM 
        RankedOrders ro
    JOIN 
        CustomerSummary cs ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    hvo.o_orderkey,
    hvo.o_totalprice,
    COALESCE(sp.total_supply_cost, 0) AS supplier_cost
FROM 
    HighValueOrders hvo
LEFT JOIN 
    SupplierPartSummary sp ON hvo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = hvo.o_orderkey)
WHERE 
    hvo.o_orderstatus = 'O'
ORDER BY 
    hvo.o_totalprice DESC
LIMIT 10;
