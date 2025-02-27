WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01'
      AND l.l_shipdate <= DATE '2022-12-31'
    GROUP BY l.l_orderkey
),
TopOrders AS (
    SELECT l.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
    FROM orders o
    JOIN RankedSales rs ON o.o_orderkey = rs.l_orderkey
    WHERE rs.revenue_rank <= 10
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COALESCE(SUM(ps.total_available), 0) AS total_avail_qty
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN SupplierStats ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    to.o_orderkey,
    to.o_orderstatus,
    to.o_totalprice,
    CONCAT(sd.s_name, ' from ', sd.nation_name) AS supplier_info,
    sd.total_avail_qty,
    CASE 
        WHEN sd.total_avail_qty IS NULL THEN 'No availability' 
        ELSE 'Available' 
    END AS availability_status
FROM TopOrders to
LEFT JOIN SupplierDetails sd ON sd.total_avail_qty = (
    SELECT MAX(total_available) 
    FROM SupplierStats 
    WHERE ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = to.o_orderkey
    )
)
ORDER BY to.o_orderdate DESC, to.o_orderkey;
