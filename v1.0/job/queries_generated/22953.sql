WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM title t
),
ActorsWithRoles AS (
    SELECT
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
),
MoviesWithRoleCounts AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT a.actor_name) AS unique_actor_count
    FROM RankedMovies m
    LEFT JOIN ActorsWithRoles a ON m.movie_id = a.movie_id
    GROUP BY m.movie_id
),
KeywordMovies AS (
    SELECT
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS production_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(km.keywords, 'None') AS keywords,
    COALESCE(uac.unique_actor_count, 0) AS unique_actor_count,
    COALESCE(pc.production_companies, 'N/A') AS production_companies,
    CASE 
        WHEN rm.total_movies = 0 THEN 'No movies in year'
        WHEN rm.rank = 1 THEN 'First movie of the year'
        WHEN rm.rank = rm.total_movies THEN 'Last movie of the year'
        ELSE 'Mid-range movie'
    END AS movie_rank_status
FROM RankedMovies rm
LEFT JOIN KeywordMovies km ON rm.movie_id = km.movie_id
LEFT JOIN MoviesWithRoleCounts uac ON rm.movie_id = uac.movie_id
LEFT JOIN MovieCompanies pc ON rm.movie_id = pc.movie_id
WHERE
    (rm.production_year IS NOT NULL OR rm.production_year < 2023) 
    AND (rm.title ILIKE '%the%' OR rm.title IS NULL)
ORDER BY
    rm.production_year DESC, rm.title ASC
LIMIT 100;
