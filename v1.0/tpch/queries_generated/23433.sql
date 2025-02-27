WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT CASE WHEN p.p_size < 30 THEN ps.ps_suppkey END) AS small_part_suppliers
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice IS NOT NULL
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerTotalPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cu.c_custkey) AS customer_count,
    SUM(pt.total_available) AS total_available_parts,
    AVG(pt.avg_supply_cost) AS avg_supply_cost,
    MAX(o.o_orderdate) AS last_order_date,
    w.row_number AS order_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    PartSupplierDetails pt ON pt.ps_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerTotalPurchases cu ON cu.total_spent > (SELECT AVG(total_spent) FROM CustomerTotalPurchases)
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = cu.c_custkey 
CROSS JOIN 
    (SELECT ROW_NUMBER() OVER () AS row_number) w
WHERE 
    r.r_name LIKE 'A%' OR r.r_name IS NULL
GROUP BY 
    r.r_name, w.row_number 
HAVING 
    COUNT(DISTINCT cu.c_custkey) > 5 
    AND SUM(pt.total_available) IS NOT NULL 
ORDER BY 
    total_available_parts DESC, last_order_date ASC;
