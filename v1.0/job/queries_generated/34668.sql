WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        STRING_AGG(DISTINCT ak.name || ' (' || ak.md5sum || ')', ', ') AS actors
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mh.level = 1
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 3
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.num_cast,
        tm.actors,
        mi.info AS movie_notes,
        kt.keyword AS movie_keyword
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary' LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.num_cast,
    md.actors,
    COALESCE(md.movie_notes, 'No summary available') AS movie_summary,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    movie_details md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.num_cast, md.actors, md.movie_notes
ORDER BY 
    md.production_year DESC, md.num_cast DESC;
