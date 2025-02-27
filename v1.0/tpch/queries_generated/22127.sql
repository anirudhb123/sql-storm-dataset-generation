WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'N/A'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS part_size_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
OrderLineItem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(*) AS total_items
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    fp.part_size_category,
    ss.total_supply_cost,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown Status'
    END AS order_status_description,
    SUM(oli.total_line_price) FILTER (WHERE oli.total_items > 1) OVER (PARTITION BY r.r_regionkey) AS sum_lines_high_volume
FROM RankedOrders o
JOIN nation n ON o.o_orderkey % 25 = n.n_nationkey  -- Simulating a bizarre foreign key relationship
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN FilteredParts fp ON o.o_orderkey % 100 = fp.p_partkey  -- Bizarre join condition
LEFT JOIN SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN OrderLineItem oli ON o.o_orderkey = oli.l_orderkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (ss.total_supply_cost IS NOT NULL OR fp.p_retailprice < 50.00)
ORDER BY 
    r.r_name, 
    o.o_totalprice DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
