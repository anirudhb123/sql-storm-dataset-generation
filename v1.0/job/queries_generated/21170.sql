WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank,
        COUNT(tc.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        total_cast
    FROM 
        RankedMovies
    WHERE 
        total_cast > 5 -- Only include movies with more than 5 cast members
),
RecentMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast
    FROM 
        FilteredMovies
    WHERE 
        production_year = (SELECT MAX(production_year) FROM FilteredMovies)
),
MovieKeywords AS (
    SELECT 
        m.movie_title,
        k.keyword 
    FROM 
        FilteredMovies m
    JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.movie_title)
    JOIN 
        keyword k ON k.id = mk.keyword_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COALESCE((SELECT STRING_AGG(keyword, ', ') FROM MovieKeywords mk WHERE mk.movie_title = rm.movie_title), 'No Keywords') AS keywords,
    (SELECT 
        COUNT(DISTINCT ci.person_id) 
     FROM 
        cast_info ci 
     JOIN 
        aka_name an ON ci.person_id = an.person_id
     WHERE 
        ci.movie_id = (SELECT id FROM aka_title WHERE title = rm.movie_title) 
        AND an.name ILIKE '%Smith%') AS smith_count,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = (SELECT id FROM aka_title WHERE title = rm.movie_title)
        AND mi.info ILIKE '%Award%') AS award_count
FROM 
    RecentMovies rm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = rm.movie_title)
WHERE 
    cc.status_id IS NULL -- Ensure we only get movies with complete cast info
ORDER BY 
    rm.production_year DESC;
