WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF((
            SELECT STRING_AGG(c.name, ', ')
            FROM complete_cast cc
            JOIN aka_name c ON cc.subject_id = c.person_id
            WHERE cc.movie_id = m.id
        ), ''), 'Unknown') AS cast_names,
        COALESCE(NULLIF((
            SELECT STRING_AGG(CONCAT('[', ct.kind, '] ', co.name), ', ')
            FROM movie_companies mc
            JOIN company_name co ON mc.company_id = co.id
            JOIN company_type ct ON mc.company_type_id = ct.id
            WHERE mc.movie_id = m.id
        ), ''), 'No Production Companies') AS production_companies
    FROM title m
    WHERE m.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF((
            SELECT STRING_AGG(c.name, ', ')
            FROM complete_cast cc
            JOIN aka_name c ON cc.subject_id = c.person_id
            WHERE cc.movie_id = ml.linked_movie_id
        ), ''), 'Unknown') AS cast_names,
        COALESCE(NULLIF((
            SELECT STRING_AGG(CONCAT('[', ct.kind, '] ', co.name), ', ')
            FROM movie_companies mc
            JOIN company_name co ON mc.company_id = co.id
            JOIN company_type ct ON mc.company_type_id = ct.id
            WHERE mc.movie_id = ml.linked_movie_id
        ), ''), 'No Production Companies') AS production_companies
    FROM movie_link ml
    JOIN title mt ON ml.linked_movie_id = mt.id
    WHERE ml.link_type_id = (
        SELECT id FROM link_type WHERE link = 'Sequel'
    )
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.cast_names,
    mh.production_companies,
    ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) as rank
FROM movie_hierarchy mh
WHERE mh.production_year IS NOT NULL
ORDER BY mh.production_year DESC, mh.title;