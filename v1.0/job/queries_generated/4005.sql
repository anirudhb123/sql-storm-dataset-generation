WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year, a.kind_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
    AND 
        rm.production_year > (SELECT AVG(production_year) FROM aka_title)
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    kt.keywords,
    COALESCE(c.name, 'Unknown') AS company_name
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    MovieKeywords kt ON fm.production_year = (SELECT production_year FROM aka_title WHERE id = kt.movie_id LIMIT 1)
WHERE 
    fm.cast_count IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.title;
