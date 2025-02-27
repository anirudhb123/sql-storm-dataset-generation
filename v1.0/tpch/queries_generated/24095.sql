WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
), 
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spend
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), 
HighValueCustomers AS (
    SELECT 
        cs.c_custkey
    FROM 
        CustomerSpend cs
    WHERE 
        cs.total_spend > (SELECT AVG(total_spend) FROM CustomerSpend)
), 
SupplierRatings AS (
    SELECT 
        s.s_suppkey,
        AVG(CASE 
                WHEN l.l_returnflag = 'R' THEN 1 
                ELSE 0 
            END) AS return_rate,
        COUNT(CASE 
                WHEN l.l_linestatus = 'O' THEN 1 
                ELSE NULL 
            END) AS outstanding_orders
    FROM 
        supplier s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(ps.total_availability) AS total_part_availability,
    AVG(s.avg_supply_cost) AS avg_cost,
    (SELECT COUNT(*) FROM HighValueCustomers) AS high_value_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierRatings s ON n.n_nationkey = (SELECT MAX(su.s_nationkey) FROM supplier su WHERE su.s_suppkey = s.s_suppkey)
JOIN 
    PartSupplier ps ON (SELECT MAX(p.p_partkey) FROM part p WHERE p.p_partkey = ps.p_partkey)
WHERE 
    r.r_name LIKE 'S%' 
    AND n.n_comment IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1 
    OR (SUM(ps.total_availability) IS NULL AND COUNT(DISTINCT n.n_nationkey) > 2)
ORDER BY 
    total_part_availability DESC, 
    r.r_name COLLATE Latin1_General_BIN;
