WITH PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    sd.s_name AS supplier_name,
    sd.supplier_nation,
    sd.rank_by_balance
FROM 
    part p
LEFT JOIN 
    PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrderStats cs ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    (p.p_retailprice > 50 OR p.p_brand LIKE 'Brand%') 
    AND (sd.rank_by_balance IS NULL OR sd.rank_by_balance <= 5)
ORDER BY 
    p.p_partkey, total_orders DESC;
