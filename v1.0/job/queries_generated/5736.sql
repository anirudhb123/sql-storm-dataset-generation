WITH RankedActors AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(CAST.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info CAST ON a.person_id = CAST.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(CAST.movie_id) > 5
), MoviesWithKeywords AS (
    SELECT 
        DISTINCT m.id AS movie_id, 
        m.title, 
        mk.keyword
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
), MovieCompaniesInfo AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    r.actor_name, 
    COUNT(DISTINCT mk.movie_id) AS keyworded_movies_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS associated_keywords,
    STRING_AGG(DISTINCT mci.company_name || ' (' || mci.company_type || ')', '; ') AS producing_companies
FROM 
    RankedActors r
JOIN 
    cast_info ci ON r.actor_id = ci.person_id
JOIN 
    MoviesWithKeywords mk ON ci.movie_id = mk.movie_id
JOIN 
    MovieCompaniesInfo mci ON mk.movie_id = mci.movie_id
GROUP BY 
    r.actor_id, r.actor_name
ORDER BY 
    keyworded_movies_count DESC, r.actor_name ASC
LIMIT 10;
