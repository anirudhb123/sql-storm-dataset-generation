WITH movie_summary AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
keyword_summary AS (
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
info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.cast_names,
    ks.keywords,
    is.info_details
FROM 
    movie_summary ms
LEFT JOIN 
    keyword_summary ks ON ms.movie_id = ks.movie_id
LEFT JOIN 
    info_summary is ON ms.movie_id = is.movie_id
ORDER BY 
    ms.production_year DESC, ms.cast_count DESC;
