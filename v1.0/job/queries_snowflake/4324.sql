
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.movie_id) DESC) AS rank,
        COUNT(c.movie_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.rank,
        rm.cast_count,
        mci.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT company_id) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) mci ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mci.movie_id)
    WHERE 
        rm.rank <= 5
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.rank,
    fm.cast_count,
    COALESCE(pk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = fm.movie_title LIMIT 1)) AS complete_cast_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    PopularKeywords pk ON fm.movie_title = (SELECT title FROM aka_title WHERE id = pk.movie_id LIMIT 1)
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
