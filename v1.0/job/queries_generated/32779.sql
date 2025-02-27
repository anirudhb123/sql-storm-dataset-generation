WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(t.season_nr, 0) AS season_nr,
        COALESCE(t.episode_nr, 0) AS episode_nr,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(t.season_nr, 0) AS season_nr,
        COALESCE(t.episode_nr, 0) AS episode_nr,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.id = mh.movie_id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
),
keyword_analysis AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_result AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.cast_names,
        ka.keywords,
        mh.season_nr,
        mh.episode_nr
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_stats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_analysis ka ON mh.movie_id = ka.movie_id
    WHERE 
        mh.level <= 2 
        AND mh.production_year > 2000
)

SELECT 
    fr.title,
    fr.production_year,
    COALESCE(fr.total_cast, 0) AS total_cast,
    COALESCE(fr.cast_names, 'No cast available') AS cast_names,
    COALESCE(fr.keywords, 'No keywords available') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY fr.production_year ORDER BY fr.total_cast DESC) AS rank_in_year
FROM 
    final_result fr
ORDER BY 
    fr.production_year DESC, 
    fr.total_cast DESC;
