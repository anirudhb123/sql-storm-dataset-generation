WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
TopRevenueCustomers AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.rank <= 10
    GROUP BY 
        r.r_name
),
SupplierPartStats AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
FinalReport AS (
    SELECT 
        t.region_name,
        t.total_revenue,
        s.supplier_name,
        s.part_name,
        s.total_available_quantity,
        s.average_supply_cost
    FROM 
        TopRevenueCustomers t
    LEFT JOIN 
        SupplierPartStats s ON t.region_name = (
            SELECT r.r_name
            FROM region r
            JOIN nation n ON r.r_regionkey = n.n_regionkey
            JOIN customer c ON n.n_nationkey = c.c_nationkey
            WHERE c.c_custkey = (
                SELECT o.o_custkey
                FROM orders o
                WHERE o.o_orderkey = (
                    SELECT MIN(o2.o_orderkey)
                    FROM orders o2
                    JOIN customer c2 ON o2.o_custkey = c2.c_custkey
                    WHERE c2.c_nationkey = (
                        SELECT c3.c_nationkey
                        FROM customer c3
                        WHERE c3.c_custkey = t.o_custkey
                    )
                    LIMIT 1
                )
            )
        )
    ORDER BY 
        t.total_revenue DESC, 
        s.average_supply_cost ASC
)
SELECT * FROM FinalReport;
