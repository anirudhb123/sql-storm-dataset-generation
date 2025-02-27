WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
LatestCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY mc.id DESC) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ActorsWithMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
)
SELECT 
    at.person_id,
    an.name AS actor_name,
    COUNT(DISTINCT t.id) AS total_movies,
    STRING_AGG(DISTINCT lt.linked_movie_id::TEXT, ', ') AS linked_movies,
    CASE 
        WHEN mwc.movie_count IS NULL THEN 'No Roles'
        ELSE mwc.movie_count::TEXT || ' Roles'
    END AS role_summary,
    COALESCE(cn.name, 'Independent') AS company_name,
    COALESCE(ct.kind, 'N/A') AS company_type
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    LatestCompanies cn ON cn.movie_id = t.id AND cn.company_rank = 1
LEFT JOIN 
    company_type ct ON ct.id = cn.company_type_id
LEFT JOIN 
    ActorsWithMovieCounts mwc ON mwc.person_id = ci.person_id
LEFT JOIN 
    movie_link lt ON lt.movie_id = t.id
WHERE 
    t.production_year >= 1990
GROUP BY 
    at.person_id, an.name, mwc.movie_count, cn.name, ct.kind
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    COUNT(DISTINCT t.id) DESC, an.name;
