WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > (SELECT AVG(ps_inner.ps_availqty) FROM partsupp ps_inner WHERE ps_inner.ps_partkey = ps.ps_partkey)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSpend AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spend
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        a.p_partkey,
        a.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        AvailableParts a
    JOIN 
        partsupp ps ON a.p_partkey = ps.ps_partkey
    GROUP BY 
        a.p_partkey, a.p_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    r.s_name AS top_supplier,
    ps.p_name AS part_name,
    ps.total_supply_cost,
    (CASE 
        WHEN cs.total_spend IS NULL THEN 'No Orders Yet' 
        ELSE CAST(cs.total_spend AS VARCHAR)
    END) AS customer_spending,
    (SELECT COUNT(*) FROM RecentOrders ro WHERE ro.total_value > 10000) AS high_value_orders
FROM 
    CustomerSpend cs
LEFT JOIN 
    RankedSuppliers r ON cs.total_spend IS NOT NULL AND r.rank_by_balance = 1
JOIN 
    PartSupplierInfo ps ON (ps.total_supply_cost IS NOT NULL)
WHERE 
    COALESCE(cs.total_spend, 0) > 5000
ORDER BY 
    cs.total_spend DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
