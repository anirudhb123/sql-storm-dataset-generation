
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    fm.title, 
    fm.production_year,
    COALESCE((SELECT LISTAGG(an.name, ', ') 
               WITHIN GROUP (ORDER BY an.name) 
               FROM aka_name an 
               JOIN cast_info ci ON an.person_id = ci.person_id 
               WHERE ci.movie_id IN (SELECT movie_id FROM complete_cast cc WHERE cc.status_id = 1)
               AND ci.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = fm.title LIMIT 1)), 'No Cast') AS top_cast,
    (SELECT COUNT(DISTINCT mw.movie_id) 
     FROM movie_keyword mw 
     JOIN keyword k ON mw.keyword_id = k.id 
     WHERE k.keyword ILIKE '%action%' OR k.keyword ILIKE '%comedy%') AS action_comedy_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
