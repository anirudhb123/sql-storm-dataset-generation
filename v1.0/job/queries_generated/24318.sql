WITH RecursiveRole AS (
    SELECT 
        ci.person_id, 
        c.kind AS role,
        ci.movie_id,
        ROW_NUMBER() OVER(PARTITION BY ci.person_id ORDER BY ci.nr_order) AS rn
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
),
MovieWithDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.movie_id
    WHERE 
        ak.name IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        m.movie_title, 
        m.production_year,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        MovieWithDetails m
    LEFT JOIN 
        CompanyCounts cc ON m.movie_id = cc.movie_id
    WHERE 
        m.production_year IS NOT NULL
    ORDER BY 
        company_count DESC, m.production_year ASC
)
SELECT 
    t.movie_title,
    t.production_year,
    STRING_AGG(DISTINCT CONCAT(a.actor_name, ' as ', r.role) ORDER BY a.actor_name) AS actors,
    t.company_count
FROM 
    TopMovies t
JOIN 
    RecursiveRole r ON t.movie_id = r.movie_id
JOIN 
    aka_name a ON r.person_id = a.person_id
WHERE 
    t.company_count > 0
GROUP BY 
    t.movie_title, t.production_year, t.company_count
HAVING 
    COUNT(DISTINCT r.role) FILTER (WHERE r.role IS NOT NULL) > 1
ORDER BY 
    t.company_count DESC, t.production_year DESC
LIMIT 10;
