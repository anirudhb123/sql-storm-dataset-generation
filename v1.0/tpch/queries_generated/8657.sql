WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 10
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 5000
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    rp.rank,
    rp.p_name,
    rp.total_available_quantity,
    rp.average_supply_cost,
    ts.s_name AS top_supplier,
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.line_item_count
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON ts.supplied_parts_count > 5
JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey < 10000)
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.total_available_quantity DESC, 
    hvo.o_totalprice DESC;
