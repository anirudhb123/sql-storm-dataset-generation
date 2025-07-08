
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(NULL AS INTEGER) AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
extended_movie_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COALESCE(ki.keyword, 'NoKeyword') AS keyword,
        COUNT(ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aliases
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level, ki.keyword
),
ranked_movies AS (
    SELECT 
        emi.movie_id,
        emi.title,
        emi.production_year,
        emi.level,
        emi.keyword,
        emi.cast_count,
        emi.aliases,
        RANK() OVER (PARTITION BY emi.level ORDER BY emi.cast_count DESC) AS rank_by_cast
    FROM 
        extended_movie_info emi
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count,
        rm.aliases,
        rm.rank_by_cast
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_cast <= 10 AND (rm.keyword IS NOT NULL OR rm.aliases IS NOT NULL)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keyword,
    fm.cast_count,
    fm.aliases,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')) THEN 'Summary Available' 
        ELSE 'No Summary' 
    END AS summary_status
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
