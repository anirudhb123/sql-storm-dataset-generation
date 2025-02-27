WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        UPPER(TRIM(p.p_name)) AS part_name, 
        p.p_brand, 
        p.p_type, 
        CONCAT(p.p_container, ' - ', p.p_comment) AS full_description, 
        p.p_retailprice, 
        REPLACE(p.p_comment, 'fragile', 'delicate') AS modified_comment
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_nationkey, 
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_balance,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent, 
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    nd.n_name AS nation_name,
    pd.part_name,
    pd.full_description,
    ss.total_suppliers,
    cs.total_orders,
    cs.total_spent
FROM 
    nation nd
JOIN 
    PartDetails pd ON nd.n_nationkey IN (SELECT s_nationkey FROM supplier)
JOIN 
    SupplierStats ss ON ss.s_nationkey = nd.n_nationkey
JOIN 
    CustomerOrders cs ON cs.o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = nd.n_nationkey)
WHERE 
    pd.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
ORDER BY 
    total_spent DESC, 
    part_name;
