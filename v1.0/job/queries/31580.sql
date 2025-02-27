WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           mh.depth + 1
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT c.movie_id, STRING_AGG(a.name, ', ') AS cast_names,
           COUNT(c.person_id) AS num_cast
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieCompanies AS (
    SELECT mc.movie_id, STRING_AGG(DISTINCT cn.name, '; ') AS companies,
           STRING_AGG(DISTINCT ct.kind, '; ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT mh.movie_id, mh.title, mh.production_year,
       COALESCE(cd.cast_names, 'No Cast') AS cast_names,
       COALESCE(cd.num_cast, 0) AS num_cast,
       COALESCE(kw.keywords, 'No Keywords') AS keywords,
       COALESCE(comp.companies, 'No Companies') AS companies,
       COALESCE(comp.company_types, 'No Company Types') AS company_types,
       ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank
FROM MovieHierarchy mh
LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN MovieKeywords kw ON mh.movie_id = kw.movie_id
LEFT JOIN MovieCompanies comp ON mh.movie_id = comp.movie_id
WHERE mh.depth <= 2
ORDER BY mh.production_year DESC, mh.title;
