WITH RankedOrders AS (
    SELECT 
        o.orderkey AS order_key,
        o.totalprice,
        o.orderdate,
        RANK() OVER (PARTITION BY o.orderstatus ORDER BY o.totalprice DESC) AS rank_per_status
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.partkey, 
        ps.suppkey, 
        (ps.availqty * ps.supplycost) AS supply_value
    FROM 
        partsupp ps
    WHERE 
        ps.availqty > 0
),
PartsWithComments AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        COALESCE(SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS returns_count,
        COUNT(DISTINCT ps.suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    LEFT JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    LEFT JOIN 
        SupplierParts ps ON p.p_partkey = ps.partkey
    LEFT JOIN 
        supplier s ON ps.suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container, p.p_retailprice
)
SELECT 
    r.r_name,
    SUM(CASE WHEN o.orderstatus = 'O' THEN o.totalprice ELSE 0 END) AS total_open_orders,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE WHEN p.returns_count > 0 THEN 1 ELSE 0 END) AS returned_parts,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts,
    MAX(p.supplier_count) AS max_suppliers,
    STRING_AGG(DISTINCT p.supplier_names, '; ') AS supplier_list
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    PartsWithComments p ON o.o_orderkey = p.p_partkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(o.o_orderkey) > 10
ORDER BY 
    total_open_orders DESC
LIMIT 10;
