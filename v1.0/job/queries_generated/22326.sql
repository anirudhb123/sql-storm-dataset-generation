WITH RecursiveActorMovies AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        at.title,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS rn,
        at.production_year,
        COUNT(*) OVER (PARTITION BY ca.person_id) AS total_movies
    FROM 
        cast_info ca
    JOIN 
        aka_title at ON ca.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
LatestMovies AS (
    SELECT 
        ram.person_id,
        ram.movie_id,
        ram.title,
        ram.production_year,
        ram.total_movies
    FROM 
        RecursiveActorMovies ram
    WHERE 
        ram.rn = 1
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    a.name AS actor_name,
    lm.title AS latest_movie,
    lm.production_year,
    lm.total_movies,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords
FROM 
    aka_name a
JOIN 
    RecursiveActorMovies ram ON a.person_id = ram.person_id
JOIN 
    LatestMovies lm ON ram.movie_id = lm.movie_id
LEFT JOIN 
    MovieKeywords mk ON lm.movie_id = mk.movie_id
WHERE 
    a.name IS NOT NULL
    AND lm.production_year >= (SELECT AVG(production_year) FROM aka_title WHERE production_year IS NOT NULL)
    AND lm.total_movies > 1
ORDER BY 
    lm.production_year DESC,
    a.name;

-- Outer Join Example 
SELECT 
    a.name AS actor_name,
    COALESCE(m.title, 'No movies') AS title,
    COALESCE(m.production_year, 'Unknown Year') as production_year
FROM 
    aka_name a
LEFT JOIN 
    (SELECT 
        ca.person_id, 
        at.title, 
        at.production_year
    FROM 
        cast_info ca
    JOIN 
        aka_title at ON ca.movie_id = at.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    ) m ON a.person_id = m.person_id
ORDER BY 
    a.name;

-- Correlated Subquery Example 
SELECT 
    a.name,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.person_id = a.person_id) AS movie_count
FROM 
    aka_name a
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_companies mc
        WHERE mc.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
          AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
    )
ORDER BY 
    movie_count DESC;

-- Bizarre NULL Logic Case
SELECT 
    a.name,
    COUNT(DISTINCT ca.movie_id) AS movie_count,
    SUM(CASE WHEN ca.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info ca ON a.person_id = ca.person_id
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT ca.movie_id) > 0
    OR (SUM(CASE WHEN ca.note IS NULL THEN 1 ELSE 0 END) > 0 AND COUNT(DISTINCT ca.movie_id) = 0)
ORDER BY 
    movie_count DESC;
