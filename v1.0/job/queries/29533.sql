WITH 

movie_keywords AS (
    SELECT mt.movie_id, 
           title.title AS movie_title, 
           STRING_AGG(kw.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword kw ON mt.keyword_id = kw.id
    JOIN title ON mt.movie_id = title.id
    GROUP BY mt.movie_id, title.title
),


cast_info_details AS (
    SELECT ci.movie_id,
           STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
           STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),


movie_company_info AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies,
           MIN(mt.production_year) AS earliest_production_year
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN title mt ON mc.movie_id = mt.id
    GROUP BY mc.movie_id
)


SELECT mkv.movie_title,
       mkv.keywords,
       cid.cast_names,
       cid.roles,
       cmi.companies,
       cmi.earliest_production_year
FROM movie_keywords mkv
JOIN cast_info_details cid ON mkv.movie_id = cid.movie_id
JOIN movie_company_info cmi ON mkv.movie_id = cmi.movie_id
ORDER BY mkv.movie_title;