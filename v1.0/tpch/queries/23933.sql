
WITH RegionalStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(CASE WHEN ps.ps_availqty IS NULL THEN 1 END) AS null_availqty_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderLineMetrics AS (
    SELECT 
        l.l_orderkey,
        MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_item_value,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returned_items_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    r.nation_count,
    COALESCE(acs.total_spent, 0) AS high_spending_customer_total,
    COALESCE(ps.supplier_count, 0) AS part_supplier_count,
    ps.avg_supplycost,
    ol.max_item_value,
    ol.returned_items_count
FROM 
    RegionalStats r
LEFT JOIN 
    HighSpendingCustomers acs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = acs.c_custkey LIMIT 1)
LEFT JOIN 
    PartSupplierStats ps ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%' ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    OrderLineMetrics ol ON ol.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' ORDER BY RANDOM() LIMIT 1)
WHERE 
    (r.total_acctbal IS NULL OR r.total_acctbal > 5000)
ORDER BY 
    r.r_name;
