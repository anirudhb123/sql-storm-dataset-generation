WITH ranked_movies AS (
    SELECT 
        mt.id as movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_by_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
cast_movie_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(CONCAT_WS(' ', coalesce(an.first_name, ''), coalesce(an.last_name, ''))) AS actors_names,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = cc.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        mt.*,
        r.rank_by_year,
        c.actors_names,
        c.keywords,
        c.cast_count
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_movie_info c ON r.movie_id = c.movie_id
    JOIN 
        aka_title mt ON mt.id = r.movie_id
    WHERE 
        r.rank_by_year <= 5
),
possible_related_movies AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        lt.link AS relation_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
)
SELECT 
    md.*,
    COALESCE(ARRAY_AGG(DISTINCT prm.linked_movie_id) FILTER (WHERE prm.linked_movie_id IS NOT NULL), '{}') AS related_movies,
    COALESCE(CAST(AVG(ci.nr_order) AS DECIMAL), 0.0) AS average_cast_order
FROM 
    movie_details md
LEFT JOIN 
    possible_related_movies prm ON md.movie_id = prm.movie_id
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.rank_by_year, md.actors_names, md.keywords, md.cast_count
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 OR 
    COUNT(DISTINCT prm.linked_movie_id) > 0
ORDER BY 
    md.production_year DESC, md.rank_by_year ASC;
