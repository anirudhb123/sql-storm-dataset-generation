WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.c_acctbal, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate < co.o_orderdate
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1 OR l.l_tax < 0.05
)
SELECT 
    co.c_name,
    co.o_orderkey,
    COALESCE(pl.total_availability, 0) AS total_availability,
    SUM(fli.l_extendedprice * (1 - fli.l_discount)) AS total_revenue,
    CASE 
        WHEN COUNT(fli.l_orderkey) > 5 THEN 'High Volume' 
        ELSE 'Low Volume' 
    END AS order_volume
FROM 
    CustomerOrders co
LEFT JOIN 
    FilteredLineItems fli ON co.o_orderkey = fli.l_orderkey
LEFT JOIN 
    PartSupplier pl ON fli.l_partkey = pl.ps_partkey
WHERE 
    co.o_orderstatus IN ('O', 'F')
GROUP BY 
    co.c_name, co.o_orderkey, pl.total_availability
ORDER BY 
    total_revenue DESC;
