WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SD.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(CO.total_orders, 0) AS customer_order_count,
    COALESCE(CO.total_spent, 0) AS total_spent,
    R.o_orderkey AS top_orderkey,
    R.o_totalprice AS top_order_totalprice,
    R.o_orderstatus AS top_order_status
FROM 
    nation n
LEFT JOIN 
    (SELECT 
         ns.n_nationkey,
         SD.s_name,
         SD.total_supply_cost
     FROM 
         SupplierDetails SD 
     JOIN 
         nation ns ON SD.s_nationkey = ns.n_nationkey) AS SD ON n.n_nationkey = SD.n_nationkey
FULL OUTER JOIN 
    CustomerOrders CO ON CO.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    RankedOrders R ON R.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' ORDER BY o.o_totalprice DESC LIMIT 1)
WHERE 
    (SD.total_supply_cost IS NOT NULL OR CO.total_orders > 0)
ORDER BY 
    n.n_name, total_spent DESC;