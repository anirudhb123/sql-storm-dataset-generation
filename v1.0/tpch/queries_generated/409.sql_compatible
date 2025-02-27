
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
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
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(l.l_extendedprice) AS avg_extended_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    ss.s_suppkey,
    ss.s_name,
    pd.p_partkey,
    pd.p_name,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(ss.total_parts, 0) AS supplier_part_count,
    pd.avg_extended_price
FROM 
    CustomerOrders cs
FULL OUTER JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
JOIN 
    PartDetails pd ON pd.p_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = ss.s_suppkey 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
WHERE 
    COALESCE(cs.total_spent, 0) > 1000
ORDER BY 
    cs.c_name, ss.s_name;
