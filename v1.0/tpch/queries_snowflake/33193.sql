
WITH RECURSIVE supplier_ledger AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000

    UNION ALL

    SELECT 
        sl.s_suppkey,
        sl.s_name,
        sl.s_acctbal * 0.9 AS s_acctbal,
        level + 1
    FROM 
        supplier_ledger sl
    WHERE 
        sl.s_acctbal * 0.9 > 1000
),
part_availability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 10000
),
final_report AS (
    SELECT 
        pa.p_name,
        pa.total_availqty,
        hv.o_orderkey,
        hv.o_totalprice,
        hv.o_orderdate,
        sl.s_name,
        sl.s_acctbal
    FROM 
        part_availability pa
    LEFT JOIN 
        lineitem l ON pa.p_partkey = l.l_partkey
    LEFT JOIN 
        high_value_orders hv ON l.l_orderkey = hv.o_orderkey
    LEFT JOIN 
        supplier_ledger sl ON l.l_suppkey = sl.s_suppkey
    WHERE 
        pa.total_availqty > 1000
    ORDER BY 
        pa.total_availqty DESC, hv.o_totalprice DESC
)
SELECT 
    f.p_name,
    f.total_availqty,
    f.o_orderkey,
    f.o_totalprice,
    f.o_orderdate,
    f.s_name,
    COALESCE(f.s_acctbal, 0) AS s_acctbal,
    CASE 
        WHEN f.o_totalprice IS NULL THEN 'No Order'
        ELSE 'Order Placed'
    END AS order_status
FROM 
    final_report f
WHERE 
    f.total_availqty > (SELECT AVG(total_availqty) FROM part_availability)
    AND f.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
ORDER BY 
    f.o_orderdate DESC NULLS LAST;
