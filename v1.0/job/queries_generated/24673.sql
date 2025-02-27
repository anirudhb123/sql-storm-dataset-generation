WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count_rank,
        COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count_rank,
        movie_keyword,
        total_actors,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        actor_count_rank <= 3
),
NullHandling AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count_rank,
        movie_keyword,
        total_actors,
        COALESCE(NULLIF(actor_names, ''), 'No Actors Listed') AS actor_names
    FROM 
        FilteredMovies
)
SELECT 
    nm.name AS company_name,
    nm.country_code,
    f.title,
    f.production_year,
    f.actor_names,
    f.total_actors
FROM 
    NullHandling f
JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
JOIN 
    company_name nm ON mc.company_id = nm.id
WHERE 
    f.production_year IS NOT NULL
    AND (total_actors > 0 OR f.actor_names IS NOT NULL)
UNION ALL
SELECT 
    nm.name AS company_name,
    nm.country_code,
    'Unknown Movie' AS title,
    YEAR(CURRENT_DATE) AS production_year,
    'No Actor Information' AS actor_names,
    0 AS total_actors
FROM 
    company_name nm
WHERE 
    nm.country_code = 'Unknown'
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_companies mc
        WHERE nm.id = mc.company_id
    )
ORDER BY 
    production_year DESC, 
    total_actors DESC NULLS LAST;
