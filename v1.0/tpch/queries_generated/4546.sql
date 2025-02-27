WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(sd.nation_name, 'Unknown') AS supplier_nation,
    hvli.total_line_value,
    sr.order_rank
FROM 
    RankedOrders sr
LEFT JOIN 
    HighValueLineItems hvli ON sr.o_orderkey = hvli.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.total_supply_cost = (
        SELECT MAX(sd2.total_supply_cost)
        FROM SupplierDetails sd2
        WHERE sd2.nation_name = sr.o_orderstatus
    )
WHERE 
    sr.order_rank <= 10
ORDER BY 
    o.o_orderdate;
