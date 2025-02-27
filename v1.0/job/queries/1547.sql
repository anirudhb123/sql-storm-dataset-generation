
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn 
    FROM 
        title t 
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
MovieInfoExtended AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.title AS movie_title, 
    m.production_year,
    COALESCE(mk.keyword_count, 0) AS total_keywords,
    COALESCE(mie.info_details, 'No Details') AS movie_info,
    a.name AS actor_name,
    COUNT(DISTINCT ci.person_id) AS total_actors
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.title_id = mk.movie_id
LEFT JOIN 
    MovieInfoExtended mie ON m.title_id = mie.movie_id
LEFT JOIN 
    cast_info ci ON m.title_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    m.title_id, m.title, m.production_year, mk.keyword_count, mie.info_details, a.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    m.production_year DESC, m.title;
