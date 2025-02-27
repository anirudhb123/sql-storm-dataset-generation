WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mci.company_count, 0) AS company_count,
        COALESCE(mkw.keyword_count, 0) AS keyword_count
    FROM 
        TopMovies tm 
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mci ON tm.movie_id = mci.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM 
            movie_keyword mk
        GROUP BY 
            mk.movie_id
    ) mkw ON tm.movie_id = mkw.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 10 THEN 'Highly Tagged'
        WHEN md.keyword_count BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Few Tags'
    END AS tag_evaluation
FROM 
    MovieDetails md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, md.company_count DESC;
