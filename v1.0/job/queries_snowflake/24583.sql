
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        MAX(ci.role_id) AS max_role,
        MIN(ci.nr_order) AS min_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieCompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fa.total_movies,
        mcc.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredActors fa ON rm.movie_id = (SELECT MAX(c.movie_id) FROM cast_info c WHERE c.person_id = fa.person_id)
    LEFT JOIN 
        MovieCompanyCount mcc ON rm.movie_id = mcc.movie_id
    WHERE 
        fa.total_movies IS NOT NULL OR mcc.company_count IS NOT NULL
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.total_movies, 0) AS total_actors_in_movies,
    COALESCE(m.company_count, 0) AS num_of_companies,
    CASE 
        WHEN m.company_count > 5 THEN 'High Production'
        WHEN m.company_count BETWEEN 1 AND 5 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_scale,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    MoviesWithActors m
WHERE 
    (m.total_movies IS NOT NULL OR m.company_count IS NOT NULL)
    AND (m.production_year BETWEEN 1990 AND 2023)
ORDER BY 
    m.production_year DESC, m.title
FETCH FIRST 100 ROWS ONLY;
