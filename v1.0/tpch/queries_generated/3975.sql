WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
CustomerTotal AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT
    r.r_name,
    ps.p_partkey,
    ps.total_available,
    ps.avg_supply_cost,
    ct.total_spent,
    CASE 
        WHEN ct.total_spent IS NULL THEN 'No purchases'
        ELSE CONCAT('Spent: $', ROUND(ct.total_spent, 2))
    END AS customer_spending,
    o.o_orderstatus,
    o.o_orderdate
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    PartSupplierInfo psi ON ps.ps_partkey = psi.p_partkey
LEFT JOIN 
    CustomerTotal ct ON ct.c_custkey = (SELECT c.c_custkey 
                                          FROM customer c 
                                          WHERE c.c_address LIKE '%' || r.r_name || '%' 
                                          LIMIT 1)
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (SELECT o.o_orderkey 
                                        FROM RankedOrders o 
                                        ORDER BY o.o_orderdate DESC 
                                        LIMIT 1)
WHERE 
    ps.total_available > 0
ORDER BY 
    r.r_name, ps.p_partkey;
