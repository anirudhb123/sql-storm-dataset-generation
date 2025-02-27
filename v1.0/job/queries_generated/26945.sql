WITH FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 AND 
        (k.keyword ILIKE '%action%' OR k.keyword ILIKE '%adventure%')
),
MovieCast AS (
    SELECT 
        cm.movie_id,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        cm.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CONCAT(it.info, ': ', mi.info), '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    mc.cast_names,
    mi.info_details
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieCast mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON fm.movie_id = mi.movie_id
ORDER BY 
    fm.production_year DESC;
