WITH CustomerCountry AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        n.n_name AS nation, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
), 
SupplierPart AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_name
) 
SELECT 
    cc.nation,
    cc.c_name,
    cc.order_count,
    cc.total_spent,
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.total_available_qty,
    CONCAT('Customer ', cc.c_name, ' from ', cc.nation, ' has spent a total of $', ROUND(cc.total_spent, 2), 
           ' and has made ', cc.order_count, ' orders. Supplier ', sp.s_name, 
           ' supplies part ', sp.p_name, ' with total available quantity ', sp.total_available_qty, '.') AS summary
FROM 
    CustomerCountry cc
JOIN 
    SupplierPart sp ON cc.total_spent > (SELECT AVG(total_spent) FROM CustomerCountry) 
                     AND sp.total_available_qty > 100
ORDER BY 
    cc.total_spent DESC;
