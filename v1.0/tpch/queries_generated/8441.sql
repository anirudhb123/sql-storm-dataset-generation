WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT s.s_name) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        sp.total_available,
        sp.avg_supply_cost,
        sp.supplier_count
    FROM 
        part p
    JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    pd.p_name AS part_name,
    pd.p_brand AS part_brand,
    pd.p_retailprice AS retail_price,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.o_totalprice) AS total_revenue,
    AVG(ro.o_totalprice) AS avg_order_value,
    pd.total_available AS available_quantity,
    pd.avg_supply_cost AS average_supply_cost,
    pd.supplier_count AS unique_suppliers
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    pd.supplier_count > 5
GROUP BY 
    r.r_name, pd.p_name, pd.p_brand, pd.p_retailprice, pd.total_available, pd.avg_supply_cost, pd.supplier_count
ORDER BY 
    total_revenue DESC
LIMIT 10;
