WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
), 
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        GROUP_CONCAT(DISTINCT pn.name) AS cast_names,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        AVG(pn.gender = 'F') AS female_cast_ratio
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        name pn ON ci.person_id = pn.imdb_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    md.movie_id,
    md.title,
    md.cast_names,
    md.production_companies,
    md.female_cast_ratio,
    CASE 
        WHEN md.production_companies > 5 THEN 'High Production'
        ELSE 'Low Production'
    END AS production_category
FROM 
    MovieDetails md
WHERE 
    md.female_cast_ratio IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.production_companies DESC;
