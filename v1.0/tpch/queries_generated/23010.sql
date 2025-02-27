WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL OR o.o_totalprice > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rn.o_orderkey,
    rn.o_orderstatus,
    ps.p_name,
    CONCAT(sd.s_name, ' (Account: ', sd.s_acctbal, ')') AS supplier_info,
    cs.c_name AS customer_name,
    cs.total_spent,
    CASE 
        WHEN rn.order_rank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category,
    COALESCE(p_stats.total_availability, 0) as availability,
    GREATEST(cs.total_spent, COALESCE(p_stats.avg_supply_cost, 0)) AS spend_or_cost
FROM 
    RankedOrders rn
FULL OUTER JOIN 
    PartStatistics p_stats ON rn.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = rn.o_orderkey LIMIT 1)
LEFT JOIN 
    SupplierDetails sd ON sd.part_count > 0
LEFT JOIN 
    CustomerOrders cs ON cs.total_spent > 1000.00
WHERE 
    (rn.o_orderstatus IS NULL OR rn.o_orderstatus = 'O') 
    AND (sd.s_acctbal IS NOT NULL OR sd.s_name LIKE '%Supplier%')
ORDER BY 
    rn.o_orderkey, cs.total_spent DESC;
