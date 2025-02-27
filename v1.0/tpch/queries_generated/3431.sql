WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
        AND l.l_shipdate <= '2023-06-30'
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    coalesce(f.total_price_after_discount, 0) AS total_price_after_discount,
    ss.total_supply_cost,
    ss.supplier_count
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredLineItems f ON o.o_orderkey = f.l_orderkey
LEFT JOIN 
    SupplierStats ss ON EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_size > 10 AND p.p_retailprice < 500
        )
        AND ps.ps_suppkey IN (
            SELECT s.s_suppkey
            FROM supplier s
            WHERE s.s_acctbal IS NOT NULL
        )
        AND ps.ps_partkey = f.l_orderkey
    )
ORDER BY 
    o.o_orderdate DESC, 
    o.o_totalprice ASC
FETCH FIRST 100 ROWS ONLY;
