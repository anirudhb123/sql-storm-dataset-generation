WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_account_balance,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey) AS total_lines
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
)
SELECT 
    sp.s_name AS supplier_name,
    sp.total_supply_cost AS supplier_total_cost,
    cos.c_name AS customer_name,
    cos.total_spent AS customer_total_spent,
    pi.p_name AS part_name,
    pi.p_retailprice AS part_price,
    ro.order_rank AS highest_order_rank
FROM 
    SupplierPerformance sp
JOIN 
    CustomerOrderStats cos ON cos.order_count > 5
LEFT JOIN 
    PartSupplierInfo pi ON pi.total_lines > 0
FULL OUTER JOIN 
    RankedOrders ro ON ro.o_custkey = cos.c_custkey
WHERE 
    sp.average_account_balance IS NOT NULL
    AND (sp.total_supply_cost > 10000 OR pi.p_retailprice < 50)
ORDER BY 
    sp.total_supply_cost DESC, 
    cos.total_spent ASC;
