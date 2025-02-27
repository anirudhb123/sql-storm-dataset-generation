WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorRoleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        COUNT(DISTINCT r.role) AS distinct_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
), 
CompanyMovieCounts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') FILTER (WHERE t.title IS NOT NULL) AS movie_titles
    FROM 
        movie_companies mc
    JOIN 
        aka_title t ON mc.movie_id = t.movie_id
    GROUP BY 
        mc.company_id
)

SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    rt.title AS title,
    rt.production_year,
    arc.movie_count AS actor_movie_count,
    arc.distinct_roles AS actor_distinct_roles,
    cmc.movie_count AS company_movie_count,
    cmc.movie_titles AS associated_movies
FROM 
    aka_name ak
JOIN 
    ActorRoleCounts arc ON ak.person_id = arc.person_id
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    CompanyMovieCounts cmc ON mc.company_id = cmc.company_id
WHERE 
    (arc.movie_count > 5 OR arc.distinct_roles > 3)
    AND (rt.production_year <= 2020 OR rt.production_year IS NULL)
    AND ak.name ILIKE ANY (ARRAY['%Smith%', '%Johnson%', '%Williams%']) 
ORDER BY 
    arc.movie_count DESC, 
    ak.name;

-- Note: The query incorporates multiple complex constructs including CTEs, 
-- window functions with partitioning, outer joins, and complex filtering criteria
-- such as the use of string matching and NULL logic to handle various conditions.
