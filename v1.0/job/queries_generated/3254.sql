WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        RT.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM cast_info c
    JOIN aka_name ak ON ak.person_id = c.person_id
    JOIN role_type RT ON RT.id = c.role_id
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS unique_movie_count
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN company_type ct ON ct.id = mc.company_type_id
    JOIN title m ON m.id = mc.movie_id
    GROUP BY mc.movie_id, cn.name, ct.kind
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mo.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(mo.role_name, 'Unknown Role') AS role_name,
    cm.company_name,
    cm.company_type,
    km.keywords,
    rm.year_rank,
    cm.unique_movie_count
FROM RankedMovies rm
LEFT JOIN MovieCast mo ON rm.movie_id = mo.movie_id
LEFT JOIN CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
LEFT JOIN KeywordMovies km ON rm.movie_id = km.movie_id
WHERE rm.year_rank <= 5 -- Limit to top 5 recent movies per year
ORDER BY rm.production_year DESC, rm.movie_id;
