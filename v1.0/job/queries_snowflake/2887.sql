
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        (SELECT COUNT(*)
         FROM movie_keyword mk 
         WHERE mk.movie_id = tm.movie_id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)

SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.keyword_count,
    (CASE 
        WHEN md.keyword_count IS NULL THEN 'No Keywords' 
        WHEN md.keyword_count > 0 THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END) AS keyword_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
