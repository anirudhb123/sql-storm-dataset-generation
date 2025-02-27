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
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
),
HighValueSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_type,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    COALESCE(hvs.total_supply_cost, 0) AS high_value_supply_cost,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS part_rank
FROM 
    part p
LEFT JOIN 
    CustomerSummary cs ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.r_regionkey = 1))
LEFT JOIN 
    HighValueSupplies hvs ON p.p_partkey = hvs.ps_partkey
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    part_rank, customer_total_spent DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
