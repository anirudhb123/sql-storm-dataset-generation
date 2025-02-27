WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_aggregated AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS information
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE 'Synopsis%' OR it.info LIKE 'Summary%'
    GROUP BY 
        mi.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(*) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
title_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS genre
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
)

SELECT 
    ti.movie_id,
    ti.title,
    ti.production_year,
    ti.genre,
    COALESCE(cd.cast_names, 'No cast available') AS cast_names,
    COALESCE(cd.cast_count, 0) AS cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.information, 'No synopsis available') AS information
FROM 
    title_info ti
LEFT JOIN 
    cast_details cd ON ti.movie_id = cd.movie_id
LEFT JOIN 
    movie_keywords mk ON ti.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_aggregated mi ON ti.movie_id = mi.movie_id
WHERE 
    ti.production_year >= 2000
ORDER BY 
    ti.production_year DESC, ti.title;
