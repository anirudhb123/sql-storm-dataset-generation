WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors_list
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
), 
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.kind_id, 
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Blockbuster'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Average'
            ELSE 'Indie'
        END AS film_category
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.film_category,
    (SELECT STRING_AGG(DISTINCT c.name, ', ') 
     FROM company_name c 
     JOIN movie_companies mc ON c.id = mc.company_id 
     WHERE mc.movie_id = fm.movie_id) AS production_companies,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = fm.movie_id) AS keywords,
    (SELECT STRING_AGG(DISTINCT info.info, ', ') 
     FROM movie_info info 
     WHERE info.movie_id = fm.movie_id) AS additional_info
FROM 
    FilteredMovies fm
ORDER BY 
    fm.cast_count DESC, fm.production_year DESC
LIMIT 10;
