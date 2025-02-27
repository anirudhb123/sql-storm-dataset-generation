WITH RECURSIVE RecursiveMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023 -- Filter to recent movies
    UNION ALL
    SELECT 
        lm.id,
        lm.title,
        lm.production_year,
        rm.depth + 1
    FROM 
        aka_title lm
    JOIN 
        movie_link ml ON ml.linked_movie_id = lm.id
    JOIN 
        RecursiveMovies rm ON rm.movie_id = ml.movie_id
    WHERE 
        rm.depth < 3 -- Limit to 3 levels deep in links
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON co.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY mc.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year,
        COALESCE(m.actor_count, 0) AS total_cast,
        ci.companies,
        ci.company_types
    FROM 
        RecursiveMovies rm
    LEFT JOIN 
        MovieCast m ON m.movie_id = rm.movie_id
    LEFT JOIN 
        CompanyInfo ci ON ci.movie_id = rm.movie_id
)
SELECT 
    mw.movie_id,
    mw.movie_title,
    mw.production_year,
    mw.total_cast,
    mw.companies,
    mw.company_types
FROM 
    MoviesWithDetails mw
WHERE 
    mw.production_year = (SELECT MAX(production_year) FROM RecursiveMovies) -- Latest movies
ORDER BY 
    mw.total_cast DESC, 
    mw.movie_title;
