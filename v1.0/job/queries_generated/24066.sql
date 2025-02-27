WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rank_by_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT * 
    FROM RankedMovies
    WHERE rank_by_companies = 1
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
),
FullMovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, '(no keywords)') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        TopRankedMovies m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, mk.keywords
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keywords,
    f.cast_count,
    CASE 
        WHEN f.cast_count > 10 THEN 'Blockbuster' 
        WHEN f.cast_count BETWEEN 5 AND 10 THEN 'Medium Hit' 
        ELSE 'Indie Film' 
    END AS box_office_category
FROM 
    FullMovieInfo f
WHERE 
    f.production_year BETWEEN 2000 AND 2023
    AND (f.cast_count IS NOT NULL OR f.keywords IS NOT NULL)
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 50;

-- Left Joining on the aka_name to find popular names associated with movies
WITH PopularNames AS (
    SELECT 
        a.name,
        COUNT(c.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(c.id) > 3
)
SELECT 
    fn.movie_id,
    fn.title,
    fn.cast_count,
    pn.name,
    pn.movie_count
FROM 
    FullMovieInfo fn
LEFT JOIN 
    PopularNames pn ON fn.movie_id = (
        SELECT 
            ci.movie_id
        FROM 
            cast_info ci 
        JOIN 
            aka_name an ON ci.person_id = an.person_id
        WHERE 
            an.name = pn.name
        LIMIT 1
    )
ORDER BY 
    fn.cast_count DESC, pn.movie_count DESC
LIMIT 100;

-- Final string expression with NULL handling to aggregate movie titles
SELECT 
    STRING_AGG(DISTINCT title, '; ') AS all_movies
FROM 
    aka_title
WHERE 
    kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
AND 
    title IS NOT NULL;
