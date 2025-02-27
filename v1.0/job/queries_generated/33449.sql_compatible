
WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           NULL AS parent_id 
    FROM aka_title mt 
    WHERE mt.episode_of_id IS NULL
   
    UNION ALL

    SELECT mt.id, 
           mt.title, 
           mt.production_year, 
           mh.movie_id 
    FROM aka_title mt 
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
), MovieCast AS (
    SELECT c.movie_id, 
           a.name AS actor_name, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order 
    FROM cast_info c 
    JOIN aka_name a ON c.person_id = a.person_id
), MovieCompanies AS (
    SELECT c.movie_id, 
           co.name AS company_name, 
           ct.kind AS company_type 
    FROM movie_companies c 
    JOIN company_name co ON c.company_id = co.id 
    JOIN company_type ct ON c.company_type_id = ct.id
), MovieInfo AS (
    SELECT mi.movie_id, 
           mi.info AS tagline 
    FROM movie_info mi 
    JOIN info_type it ON mi.info_type_id = it.id 
    WHERE it.info ILIKE 'tagline'
)

SELECT mh.movie_id, 
       mh.title, 
       mh.production_year, 
       COALESCE(mk.keyword_list, 'No Keywords') AS keywords, 
       COALESCE(mc.actor_list, 'No Cast') AS cast, 
       COALESCE(mco.company_name, 'No Company') AS company, 
       COALESCE(mi.tagline, 'No Tagline') AS tagline 
FROM MovieHierarchy mh
LEFT JOIN (
    SELECT mw.movie_id, 
           STRING_AGG(mk.keyword, ', ') AS keyword_list 
    FROM movie_keyword mw 
    JOIN keyword mk ON mw.keyword_id = mk.id 
    GROUP BY mw.movie_id
) mk ON mh.movie_id = mk.movie_id 
LEFT JOIN (
    SELECT movie_id, 
           STRING_AGG(actor_name, ', ') AS actor_list 
    FROM MovieCast 
    GROUP BY movie_id
) mc ON mh.movie_id = mc.movie_id 
LEFT JOIN (
    SELECT movie_id, 
           STRING_AGG(company_name || ' (' || company_type || ')', ', ') AS company_name 
    FROM MovieCompanies 
    GROUP BY movie_id
) mco ON mh.movie_id = mco.movie_id 
LEFT JOIN MovieInfo mi ON mh.movie_id = mi.movie_id 
WHERE mh.production_year >= 2000 
GROUP BY mh.movie_id, mh.title, mh.production_year, mk.keyword_list, mc.actor_list, mco.company_name, mi.tagline
ORDER BY mh.production_year DESC, mh.title
LIMIT 100;
