WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        CASE
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice
        END AS adjusted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND 
        (l.l_returnflag IS NULL OR l.l_returnflag <> 'Y')
)
SELECT 
    r.o_orderkey,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    fs.total_spent,
    fd.adjusted_price,
    RANK() OVER (PARTITION BY r.o_orderkey ORDER BY fd.adjusted_price DESC) AS price_rank
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierDetails sd ON r.o_orderkey = (SELECT o.o_orderkey 
                                           FROM lineitem l
                                           JOIN orders o ON l.l_orderkey = o.o_orderkey
                                           WHERE l.l_suppkey = sd.s_suppkey
                                           LIMIT 1)
LEFT JOIN 
    CustomerSpending fs ON r.o_orderkey = fs.c_custkey
CROSS JOIN 
    FilteredLineItems fd
WHERE 
    r.rn <= 10 AND 
    fd.l_quantity > (SELECT AVG(l.l_quantity) FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
ORDER BY 
    r.o_orderkey, price_rank;
