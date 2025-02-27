WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', ps.ps_availqty, ' and supply cost of ', ROUND(ps.ps_supplycost, 2)) AS supplier_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT('Order ', o.o_orderkey, ' placed by ', c.c_name, ' on ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD'), ' totaling ', ROUND(o.o_totalprice, 2)) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
AggregateData AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT np.n_nationkey) AS total_nations,
        COUNT(DISTINCT sp.s_suppkey) AS total_suppliers,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        region r
    JOIN 
        nation np ON r.r_regionkey = np.n_regionkey
    JOIN 
        supplier sp ON np.n_nationkey = sp.s_nationkey
    JOIN 
        orders o ON sp.s_suppkey = o.o_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    rp.r_name,
    rp.total_nations,
    rp.total_suppliers,
    rp.total_order_value,
    sp.supplier_info,
    co.order_info
FROM 
    AggregateData rp
LEFT JOIN 
    SupplierParts sp ON TRUE
LEFT JOIN 
    CustomerOrders co ON TRUE
ORDER BY 
    rp.r_name, rp.total_order_value DESC;
