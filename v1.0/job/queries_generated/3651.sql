WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keyword,
    CASE 
        WHEN mwk.cast_count > 10 THEN 'Large Cast'
        WHEN mwk.cast_count IS NULL THEN 'No Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.production_year > 2000
    AND (mwk.keyword LIKE '%Action%' OR mwk.keyword LIKE '%Comedy%')
ORDER BY 
    mwk.production_year DESC,
    mwk.title ASC
LIMIT 100;

SELECT 
    DISTINCT s.actor_name, 
    t.title
FROM 
    aka_name s
JOIN 
    cast_info ca ON s.person_id = ca.person_id
JOIN 
    aka_title t ON ca.movie_id = t.id
WHERE 
    s.name IS NOT NULL
    AND (ca.note IS NULL OR ca.note != 'Cameo')
ORDER BY 
    s.actor_name, 
    t.title;

SELECT 
    m.title,
    COALESCE(SUM(mci.company_id), 0) AS company_count
FROM 
    aka_title m
LEFT JOIN 
    movie_companies mci ON m.id = mci.movie_id
GROUP BY 
    m.title
HAVING 
    COUNT(mci.company_id) > 1
ORDER BY 
    company_count DESC
LIMIT 50;

SELECT 
    a.title,
    MIN(mci.company_id) AS first_company_id
FROM 
    aka_title a
LEFT JOIN 
    movie_companies mci ON a.id = mci.movie_id
GROUP BY 
    a.title
HAVING 
    COUNT(mci.company_id) > 0;
