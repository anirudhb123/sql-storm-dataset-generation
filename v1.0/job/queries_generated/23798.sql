WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(md.note, 'No Notes') AS movie_note,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COUNT(cc.id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title ak_t
    JOIN 
        aka_name ak ON ak_t.id = ak.name_pcode_cf
    LEFT JOIN 
        complete_cast cc ON ak_t.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON ak_t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info md ON ak_t.movie_id = md.movie_id AND md.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Comment' OR info = 'Description'
        )
    WHERE 
        ak_t.production_year BETWEEN 1990 AND 2000
    GROUP BY 
        m.id, ak_t.title, md.note, cn.name

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(md.note, 'No Notes') AS movie_note,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COUNT(cc.id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title ak_t
    JOIN 
        aka_name ak ON ak_t.id = ak.name_pcode_cf
    LEFT JOIN 
        complete_cast cc ON ak_t.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON ak_t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info md ON ak_t.movie_id = md.movie_id AND md.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Trivia'
        )
    WHERE 
        ak_t.production_year BETWEEN 2001 AND 2010
    GROUP BY 
        m.id, ak_t.title, md.note, cn.name
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.movie_note,
    mh.company_name,
    mh.cast_count,
    mh.actor_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.cast_count DESC) AS rank_by_cast_count,
    CASE 
        WHEN mh.cast_count IS NULL THEN 'No Cast Information' 
        WHEN mh.cast_count = 0 THEN 'No Cast' 
        ELSE 'Has Cast' 
    END AS cast_presence
FROM 
    MovieHierarchy mh
WHERE 
    mh.movie_id IN (
        SELECT movie_id 
        FROM movie_keyword 
        WHERE keyword_id IN (
            SELECT id FROM keyword WHERE phonetic_code IS NOT NULL AND LENGTH(keyword) > 5
        )
    )
ORDER BY 
    mh.cast_count DESC NULLS LAST;
