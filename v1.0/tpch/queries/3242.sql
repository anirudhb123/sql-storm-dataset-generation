
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_supplycost,
        ps.ps_availqty,
        p.p_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
NationalCustomerSales AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
    GROUP BY 
        n.n_name
)
SELECT 
    rp.o_orderkey,
    rp.o_orderdate,
    rp.o_totalprice,
    rp.o_orderstatus,
    sp.s_name,
    sp.p_name,
    ncs.nation,
    ncs.total_sales
FROM 
    RankedOrders rp
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey = (
        SELECT ps.ps_partkey 
        FROM SupplierParts ps 
        WHERE ps.ps_availqty > 0 
        AND ps.ps_supplycost = (
            SELECT MIN(ps2.ps_supplycost) 
            FROM SupplierParts ps2 
            WHERE ps2.ps_partkey = ps.ps_partkey
        )
        ORDER BY RANDOM()
        LIMIT 1
    )
LEFT JOIN 
    NationalCustomerSales ncs ON ncs.total_sales > 100000
WHERE 
    rp.rnk = 1
ORDER BY 
    rp.o_orderdate DESC, 
    rp.o_totalprice DESC;
