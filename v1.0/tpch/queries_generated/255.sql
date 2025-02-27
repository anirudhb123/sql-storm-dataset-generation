WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_availqty ELSE 0 END) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
CustomerAggregate AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    COALESCE(oss.total_revenue, 0) AS total_revenue,
    ss.total_parts,
    ss.total_supply_cost,
    cs.total_spent,
    cs.order_count,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'Inactive'
        WHEN cs.total_spent > 10000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_type
FROM 
    CustomerAggregate cs
LEFT JOIN 
    OrderDetails oss ON cs.order_count > 0 AND oss.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = cs.c_custkey 
        ORDER BY o.o_orderdate DESC LIMIT 1
    )
LEFT JOIN 
    SupplierSummary ss ON ss.total_parts > 0
WHERE 
    cs.total_spent IS NOT NULL OR ss.total_supply_cost > 0
ORDER BY 
    cs.total_spent DESC, ss.total_supply_cost DESC;
