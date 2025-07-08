
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
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    TR.title,
    TR.production_year,
    TR.cast_count,
    COALESCE(MK.keywords, 'No keywords') AS keywords,
    COALESCE(PI.info, 'No info') AS additional_info
FROM 
    TopRankedMovies TR
LEFT JOIN 
    MovieKeywords MK ON TR.movie_id = MK.movie_id
LEFT JOIN 
    movie_info MI ON TR.movie_id = MI.movie_id
LEFT JOIN 
    info_type IT ON MI.info_type_id = IT.id
LEFT JOIN 
    person_info PI ON PI.person_id = (SELECT person_id FROM cast_info WHERE movie_id = TR.movie_id ORDER BY nr_order LIMIT 1)
WHERE 
    (TR.cast_count > 0 OR MK.keywords IS NOT NULL)
ORDER BY 
    TR.production_year DESC, TR.cast_count DESC;
