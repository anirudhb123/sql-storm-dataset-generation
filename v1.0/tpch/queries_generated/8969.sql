WITH SuppPartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
), OrderDetailed AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price,
        COUNT(DISTINCT li.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS number_of_nations,
    SUM(s.s_acctbal) AS total_supplier_balance,
    AVG(oss.total_price) AS average_order_value,
    MAX(ss.total_available_qty) AS max_available_quantity,
    ss.avg_supply_cost AS average_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SuppPartStats ss ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
LEFT JOIN 
    OrderDetailed oss ON oss.o_orderkey IN (SELECT li.l_orderkey FROM lineitem li WHERE li.l_suppkey = s.s_suppkey)
GROUP BY 
    r.r_name, ss.avg_supply_cost
HAVING 
    SUM(s.s_acctbal) > 1000000
ORDER BY 
    region_name;
