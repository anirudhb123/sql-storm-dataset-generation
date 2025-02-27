WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT
        a.id AS actor_id,
        a.name,
        c.movie_id,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY a.id, a.name, c.movie_id, r.role
),
MovieKeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
TotalActors AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM cast_info c
    GROUP BY c.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(a.role_count, 0) AS total_roles,
    COALESCE(mkc.keyword_count, 0) AS total_keywords,
    COALESCE(cd.company_count, 0) AS total_companies,
    COALESCE(ta.total_actors, 0) AS total_actors,
    CASE 
        WHEN ta.total_actors IS NULL THEN 'No actors'
        WHEN ta.total_actors < 5 THEN 'Few actors'
        ELSE 'Plenty of actors'
    END AS actor_summary,
    RANK() OVER (ORDER BY COALESCE(mkc.keyword_count, 0) DESC, m.production_year DESC) as popularity_rank,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COALESCE(mkc.keyword_count, 0) DESC) AS year_rank
FROM RankedMovies m
LEFT JOIN ActorsWithRoles a ON m.movie_id = a.movie_id
LEFT JOIN MovieKeywordCounts mkc ON m.movie_id = mkc.movie_id
LEFT JOIN CompanyDetails cd ON m.movie_id = cd.movie_id
LEFT JOIN TotalActors ta ON m.movie_id = ta.movie_id
WHERE 
    (m.production_year >= 2000 AND m.production_year <= 2020)
    AND (m.title ILIKE '%Mystery%' OR mkc.keyword_count > 0)
ORDER BY m.production_year, m.title;
