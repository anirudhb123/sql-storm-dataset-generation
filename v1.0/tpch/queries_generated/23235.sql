WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
), OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), SupplierMaxCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        MAX(ps.ps_supplycost) AS max_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_size, p.p_retailprice
), TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
), UnusualSelections AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        LENGTH(r.r_name) > 3
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_size,
    p.p_retailprice,
    COALESCE(o.total_revenue, 0) AS total_ordered_revenue,
    COALESCE(oi.item_count, 0) AS order_item_count,
    tm.total_spent AS total_customer_spent,
    us.supplier_count
FROM 
    PartInfo p
LEFT JOIN 
    OrderLineItems oi ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.order_rank <= 10))
LEFT JOIN 
    TopCustomers tm ON tm.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000)
LEFT JOIN 
    UnusualSelections us ON us.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT n_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT DISTINCT ps.ps_suppkey FROM SupplierMaxCost ps WHERE ps.max_cost = ps.ps_supplycost LIMIT 1)))
ORDER BY 
    p.p_retailprice DESC, total_ordered_revenue DESC
LIMIT 100;
