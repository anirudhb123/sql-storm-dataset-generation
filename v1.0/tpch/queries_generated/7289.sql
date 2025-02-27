WITH TotalOrderAmounts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
RankedSuppliers AS (
    SELECT 
        spd.ps_partkey,
        spd.s_suppkey,
        spd.total_supplycost,
        RANK() OVER (PARTITION BY spd.ps_partkey ORDER BY spd.total_supplycost DESC) AS rank
    FROM 
        SupplierPartDetails spd
),
TopSuppliers AS (
    SELECT 
        r.ps_partkey,
        r.s_suppkey,
        r.total_supplycost
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank = 1
)
SELECT 
    to.o_orderkey,
    COUNT(DISTINCT ts.s_suppkey) AS unique_top_suppliers,
    AVG(to.total_amount) AS average_order_amount
FROM 
    TotalOrderAmounts to
JOIN 
    TopSuppliers ts ON to.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps)        
        )
    )
GROUP BY 
    to.o_orderkey
ORDER BY 
    average_order_amount DESC
LIMIT 10;
