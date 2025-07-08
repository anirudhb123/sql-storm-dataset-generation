
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast_size
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast_size <= 3
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id, 
        LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS information
    FROM 
        movie_info mi
    JOIN 
        title mt ON mt.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
    GROUP BY 
        mt.id
)
SELECT 
    ft.title,
    ft.production_year,
    COALESCE(mi.information, 'No info available') AS box_office_info,
    ak.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 0 THEN 'Produced'
        ELSE 'Not produced'
    END AS production_status
FROM 
    FilteredTitles ft
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ft.title_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = ft.title_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = ft.title_id
GROUP BY 
    ft.title_id, ft.title, ft.production_year, mi.information, ak.name
HAVING 
    COUNT(DISTINCT ak.id) > 0
ORDER BY 
    ft.production_year DESC, 
    COUNT(DISTINCT ak.id) DESC;
