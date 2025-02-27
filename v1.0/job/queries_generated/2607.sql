WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 AND rm.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        GROUP_CONCAT(DISTINCT name.name) AS cast_names
    FROM 
        FilteredMovies fm
    INNER JOIN 
        complete_cast cc ON fm.movie_id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    INNER JOIN 
        aka_name name ON ci.person_id = name.person_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    COALESCE(ki.keywords, 'No keywords') AS keywords,
    COALESCE(mo.info, 'N/A') AS movie_info
FROM 
    MovieDetails md
LEFT JOIN (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
) ki ON md.movie_id = ki.movie_id
LEFT JOIN (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Box Office', 'Budget'))
    GROUP BY 
        mi.movie_id
) mo ON md.movie_id = mo.movie_id
WHERE 
    md.cast_count > 1
ORDER BY 
    md.production_year DESC, md.title
LIMIT 50;
