WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           1 AS depth 
    FROM aka_title m
    WHERE m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.depth + 1 
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id 
    JOIN aka_title m ON ml.linked_movie_id = m.id
),
total_cast AS (
    SELECT c.movie_id,
           COUNT(c.person_id) AS total_people,
           STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY c.movie_id
),
keywords_info AS (
    SELECT mk.movie_id,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_info AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies,
           STRING_AGG(DISTINCT ct.kind, ', ') AS company_kinds
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(tc.total_people, 0) AS total_cast_members,
       COALESCE(tc.cast_names, 'No cast available') AS cast_names,
       COALESCE(ki.keywords, 'No keywords found') AS keywords,
       COALESCE(ci.companies, 'No companies') AS production_companies,
       COALESCE(ci.company_kinds, 'No company types') AS company_types,
       mh.depth
FROM movie_hierarchy mh
LEFT JOIN total_cast tc ON mh.movie_id = tc.movie_id
LEFT JOIN keywords_info ki ON mh.movie_id = ki.movie_id
LEFT JOIN company_info ci ON mh.movie_id = ci.movie_id
WHERE mh.depth <= 2 -- Limit to top levels of hierarchy
ORDER BY mh.production_year DESC, mh.title;
