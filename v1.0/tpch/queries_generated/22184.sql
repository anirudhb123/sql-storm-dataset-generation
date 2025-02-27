WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'P')
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_retailprice,
        COALESCE(p.p_comment, 'No comment provided') AS part_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY p.p_retailprice DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0 AND 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.total_spent,
    COALESCE(spd.p_retailprice, 0) AS highest_part_price,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(spd.ps_supplycost * spd.ps_availqty) AS total_supply_cost
FROM 
    CustomerOrderSummary co
LEFT JOIN 
    RankedOrders ro ON co.c_custkey = ro.o_custkey AND ro.rn = 1
LEFT JOIN 
    SupplierPartDetails spd ON spd.s_suppkey = (SELECT TOP 1 s.s_suppkey FROM supplier s ORDER BY NEWID()) 
WHERE 
    co.total_spent > 1000 OR 
    (co.total_spent <= 1000 AND co.order_count > 5)
GROUP BY 
    co.c_name, co.total_spent, spd.p_retailprice
HAVING 
    SUM(spd.ps_supplycost * spd.ps_availqty) > 1000
ORDER BY 
    co.total_spent DESC NULLS LAST;
