WITH RECURSIVE TitleHierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.episode_of_id, t.season_nr,
           1 AS level, t.imdb_id
    FROM title t
    WHERE t.episode_of_id IS NULL
    UNION ALL
    SELECT t.id, t.title, t.production_year, t.episode_of_id, t.season_nr,
           th.level + 1 AS level, t.imdb_id
    FROM title t
    JOIN TitleHierarchy th ON t.episode_of_id = th.title_id
),
MovieInfo AS (
    SELECT mi.movie_id, 
           STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
           STRING_AGG(DISTINCT i.info, ', ') AS info
    FROM movie_info mi
    LEFT JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN info_type i ON mi.info_type_id = i.id
    GROUP BY mi.movie_id
),
CompanyDetails AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies,
           STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT th.title, th.production_year, th.level, mi.keywords, 
       cd.companies, cd.company_types,
       COALESCE(COUNT(c.person_id), 0) AS cast_count,
       AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) * 100 AS female_percentage
FROM TitleHierarchy th
LEFT JOIN complete_cast cc ON cc.movie_id = th.title_id
LEFT JOIN cast_info c ON cc.subject_id = c.id
LEFT JOIN person_info p ON c.person_id = p.person_id
LEFT JOIN MovieInfo mi ON th.id = mi.movie_id
LEFT JOIN CompanyDetails cd ON th.id = cd.movie_id
GROUP BY th.title, th.production_year, th.level, mi.keywords, 
         cd.companies, cd.company_types
ORDER BY th.production_year DESC, th.level ASC;
