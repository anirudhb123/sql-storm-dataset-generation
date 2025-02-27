WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supply_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rd.o_orderkey,
    cd.c_name,
    rp.r_name,
    sp.s_name,
    rd.o_orderdate,
    rd.o_totalprice,
    rd.o_orderstatus,
    CASE 
        WHEN rd.order_rank <= 10 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category,
    COALESCE(cd.total_spent, 0) AS customer_total_spent,
    sp.parts_supply_count,
    sp.avg_supply_cost
FROM 
    RankedOrders rd
JOIN 
    CustomerDetails cd ON cd.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'Customer%' LIMIT 1)
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = cd.c_name)
LEFT JOIN 
    region rp ON rp.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierPerformance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 100 LIMIT 1)
WHERE 
    (rd.o_orderstatus = 'O' OR rd.o_orderstatus IS NULL)
ORDER BY 
    rd.o_orderkey DESC;