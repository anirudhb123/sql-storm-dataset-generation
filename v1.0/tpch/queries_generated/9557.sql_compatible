
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
HighestSellingItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        l.l_partkey
    ORDER BY 
        revenue DESC
    LIMIT 10
),
SuppliersWithHighRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
FinalReport AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.total_available_qty,
        rp.average_supply_cost,
        hs.revenue
    FROM 
        RankedParts rp
    JOIN 
        HighestSellingItems hs ON rp.p_partkey = hs.l_partkey
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.p_retailprice,
    fr.total_available_qty,
    fr.average_supply_cost,
    fr.revenue,
    s.s_name AS supplier_name,
    s.total_revenue
FROM 
    FinalReport fr
JOIN 
    SuppliersWithHighRevenue s ON fr.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        JOIN supplier su ON ps.ps_suppkey = su.s_suppkey 
        WHERE su.s_suppkey = s.s_suppkey
    )
ORDER BY 
    fr.revenue DESC, 
    fr.p_retailprice DESC;
