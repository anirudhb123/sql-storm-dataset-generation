WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        movie_id, 
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        movie_id
),
PersonRoleCounts AS (
    SELECT 
        ci.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(ri.role) AS max_role
    FROM 
        cast_info ci
    JOIN 
        role_type ri ON ri.id = ci.role_id
    GROUP BY 
        ci.person_id
)
SELECT 
    ak.name AS actor_name, 
    m.title AS movie_title, 
    m.production_year,
    COALESCE(mkw.keywords, 'No keywords') AS movie_keywords,
    prc.movie_count AS actor_movie_count,
    prc.max_role
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ci.person_id = ak.person_id
JOIN 
    RankedMovies m ON m.movie_id = ci.movie_id AND m.rn <= 3
LEFT JOIN 
    MoviesWithKeywords mkw ON mkw.movie_id = m.movie_id
LEFT JOIN 
    PersonRoleCounts prc ON prc.person_id = ak.person_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (prc.movie_count IS NULL OR prc.movie_count > 2)
ORDER BY 
    m.production_year DESC, 
    prc.movie_count DESC NULLS LAST;