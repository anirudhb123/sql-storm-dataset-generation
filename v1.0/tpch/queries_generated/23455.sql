WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown' 
        END AS order_status_text
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(DAY, -30, GETDATE()) 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
SuspiciousLines AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_line_price
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.5 -- Discounts greater than 50%
)

SELECT 
    p.p_partkey,
    p.p_name, 
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers_list
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    FilteredOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey IN (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey
        HAVING 
            SUM(ps.ps_availqty) > 1000
    )
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0 
    AND AVG(l.l_extendedprice) IS NOT NULL 
    AND EXISTS (
        SELECT 1
        FROM SuspiciousLines sl
        WHERE sl.l_orderkey = l.l_orderkey
    )
ORDER BY 
    total_supplier_balance DESC, avg_price DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
