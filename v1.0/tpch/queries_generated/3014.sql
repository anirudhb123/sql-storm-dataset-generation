WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sd.s_name AS supplier_name,
    ca.total_spent,
    sd.num_parts,
    li.net_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierDetails sd ON n.n_nationkey = sd.s_suppkey
LEFT JOIN 
    CustomerOrders ca ON sd.s_suppkey = ca.c_custkey
JOIN 
    LineItemAnalysis li ON li.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ca.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    sd.total_supply_cost IS NOT NULL
    AND ca.total_spent > 1000
ORDER BY 
    r.r_name, n.n_name, sd.s_name;
