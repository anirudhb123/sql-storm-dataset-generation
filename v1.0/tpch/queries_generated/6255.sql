WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),

TopCustomers AS (
    SELECT 
        rc.c_custkey,
        rc.c_name
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 5
),

PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        s.s_name,
        s.s_nationkey
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        COUNT(li.l_orderkey) AS line_item_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
)

SELECT 
    c.c_custkey,
    c.c_name,
    SUM(co.o_totalprice) AS total_order_value,
    COUNT(co.o_orderkey) AS total_orders,
    COUNT(DISTINCT ps.p_partkey) AS distinct_parts,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    r.r_name AS region_name
FROM 
    TopCustomers c
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
JOIN 
    PartSupplierDetails ps ON ps.p_partkey IN (SELECT li.l_partkey FROM lineitem li JOIN orders o ON li.l_orderkey = o.o_orderkey WHERE o.o_custkey = c.c_custkey)
JOIN 
    supplier s ON ps.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    c.c_custkey, c.c_name, r.r_name
ORDER BY 
    total_order_value DESC;
