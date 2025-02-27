WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        r.revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalReport AS (
    SELECT 
        t.o_orderkey,
        t.o_orderdate,
        t.o_totalprice,
        COALESCE(sd.total_supplycost, 0) AS supplier_cost,
        t.revenue - COALESCE(sd.total_supplycost, 0) AS profit
    FROM 
        TopOrders t
    LEFT JOIN 
        SupplierDetails sd ON sd.s_suppkey = (SELECT ps.ps_suppkey 
                                              FROM partsupp ps 
                                              JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
                                              WHERE li.l_orderkey = t.o_orderkey 
                                              LIMIT 1)
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.supplier_cost,
    fr.profit
FROM 
    FinalReport fr
WHERE 
    fr.profit IS NOT NULL
ORDER BY 
    fr.profit DESC;
