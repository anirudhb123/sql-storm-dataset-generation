
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        1 AS hierarchy_level,
        mt.title,
        mt.production_year,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mh.hierarchy_level + 1,
        at.title,
        at.production_year,
        mh.movie_id
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.hierarchy_level < 3 
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        (SELECT COUNT(*) 
         FROM complete_cast cc 
         WHERE cc.movie_id = mh.movie_id) AS num_cast,
        (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
         FROM cast_info ci
         JOIN aka_name ak ON ci.person_id = ak.person_id
         WHERE ci.movie_id = mh.movie_id) AS cast_names
    FROM
        MovieHierarchy mh
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.num_cast,
    md.cast_names,
    COALESCE(
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = md.movie_id AND mc.note IS NOT NULL), 
        0
    ) AS num_companies,
    (SELECT STRING_AGG(DISTINCT kw.keyword, ', ')
     FROM movie_keyword mk
     JOIN keyword kw ON mk.keyword_id = kw.id
     WHERE mk.movie_id = md.movie_id) AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.num_cast DESC;
