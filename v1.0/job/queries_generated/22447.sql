WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mo.info, 'No Info Available') AS movie_info,
        (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
         FROM movie_companies mc 
         JOIN company_name cn ON mc.company_id = cn.id 
         WHERE mc.movie_id = tm.movie_id) AS companies,
        (SELECT COUNT(DISTINCT k.keyword) 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = tm.movie_id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mo ON tm.movie_id = mo.movie_id 
                       AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.movie_info, 'No Summary') AS summary,
    md.companies,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 10 THEN 'Popular'
        WHEN md.keyword_count IS NULL THEN 'Missing Keywords'
        ELSE 'Average'
    END AS popularity_status
FROM 
    MovieDetails md
LEFT JOIN 
    aka_name an ON md.movie_id = an.person_id 
WHERE 
    md.companies IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;

