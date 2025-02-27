WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierStatistics AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    c.c_name,
    COALESCE(co.total_spent, 0) AS customer_total_spent,
    COALESCE(o.o_orderkey, 'No Orders') AS order_identifier,
    COALESCE(rs.order_rank, 0) AS priority_order_rank,
    COALESCE(ss.total_available, 0) AS supplier_total_available,
    COALESCE(ss.avg_supply_cost, 0) AS supplier_avg_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStatistics ss ON s.s_suppkey = ss.ps_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
LEFT JOIN 
    RankedOrders o ON co.order_count > 0 AND o.o_orderkey = co.order_count
LEFT JOIN 
    (SELECT DISTINCT o_orderkey FROM orders WHERE o_orderstatus = 'O') tmp ON tmp.o_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    r.r_name, c.c_name;
