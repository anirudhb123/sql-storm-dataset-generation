WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.phonetic_code,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 1990 AND 2020
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.phonetic_code,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_with_names AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COALESCE(an.name, cn.name) AS actor_name,
        rt.role AS role_type
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        char_name cn ON ci.person_id = cn.imdb_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
movies_with_keywords AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
final_selection AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.keywords,
        COUNT(DISTINCT cn.id) AS total_actors,
        STRING_AGG(DISTINCT cw.actor_name, ', ') AS actor_names
    FROM 
        movies_with_keywords mwk
    LEFT JOIN 
        cast_with_names cw ON mwk.movie_id = cw.movie_id
    LEFT JOIN 
        aka_title at ON mwk.movie_id = at.id
    LEFT JOIN 
        movie_info mi ON mwk.movie_id = mi.movie_id AND mi.info_type_id = 1
    WHERE 
        mwk.production_year IS NOT NULL
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year, mwk.keywords
    HAVING 
        COUNT(DISTINCT cw.actor_name) > 0
)
SELECT 
    fs.title,
    fs.production_year,
    fs.keywords,
    fs.total_actors,
    fs.actor_names,
    CASE 
        WHEN fs.total_actors > 5 THEN 'Ensemble Cast' 
        WHEN fs.total_actors > 0 THEN 'Regular Cast' 
        ELSE 'No Cast' 
    END AS cast_type,
    CASE 
        WHEN fs.production_year IS NULL THEN '<Year Unknown>'
        ELSE 'Year: ' || fs.production_year
    END AS production_year_display
FROM 
    final_selection fs
ORDER BY 
    fs.production_year DESC NULLS LAST,
    fs.total_actors DESC;
