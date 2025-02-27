WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10  
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(
        (SELECT COUNT(*)
         FROM movie_keyword mk 
         WHERE mk.movie_id = fm.movie_id),
        0) AS keyword_count,
    COALESCE(
        (SELECT STRING_AGG(kn.keyword, ', ')
         FROM movie_keyword mk
         JOIN keyword kn ON mk.keyword_id = kn.id
         WHERE mk.movie_id = fm.movie_id),
    'No Keywords') AS keywords,
    (SELECT COUNT(DISTINCT(mo.company_id))
     FROM movie_companies mo 
     WHERE mo.movie_id = fm.movie_id
     AND mo.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE 'Distributor%')) AS distributor_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id
WHERE 
    (mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') AND mi.info IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM movie_info WHERE movie_id = fm.movie_id AND info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office'))
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;