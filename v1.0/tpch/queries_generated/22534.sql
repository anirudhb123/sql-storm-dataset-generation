WITH RECURSIVE SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        supplier.s_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank_cost
    FROM 
        partsupp ps
    JOIN 
        supplier ON ps.ps_suppkey = supplier.s_suppkey
    WHERE 
        ps.ps_supplycost IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_nationkey) AS row_num
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    DISTINCT 
    c.c_name,
    s.s_name,
    p.p_name,
    sd.ps_availqty,
    sd.ps_supplycost,
    COALESCE(hv.total_spent, 0) AS total_spent,
    n.region_name,
    so.o_orderdate,
    CASE 
        WHEN so.total_amount > 10000 THEN 'High'
        ELSE 'Normal'
    END AS order_status
FROM 
    SupplyDetails sd
JOIN 
    part p ON sd.ps_partkey = p.p_partkey
JOIN 
    supplier s ON sd.ps_suppkey = s.s_suppkey
LEFT JOIN 
    HighValueCustomers hv ON s.s_nationkey = hv.c_custkey
JOIN 
    NationRegion n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SuspiciousOrders so ON s.s_suppkey = so.o_orderkey 
WHERE 
    (sd.rank_cost <= 2 OR sd.ps_availqty IS NULL)
    AND p.p_size BETWEEN 10 AND 20
    AND NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_orderstatus = 'F'
        AND o.o_custkey = hv.c_custkey
    )
ORDER BY 
    total_spent DESC NULLS LAST, 
    order_status ASC, 
    s.s_name ASC;
