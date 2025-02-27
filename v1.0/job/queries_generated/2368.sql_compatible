
WITH MovieStats AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           COUNT(DISTINCT cc.subject_id) AS cast_count,
           AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS avg_info_exists,
           MAX(CASE WHEN LENGTH(m.title) > 20 THEN 1 ELSE 0 END) AS long_title_flag
    FROM title m
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id, m.title, m.production_year
),
PersonRoles AS (
    SELECT ci.movie_id,
           r.role AS person_role,
           COUNT(DISTINCT ci.person_id) AS role_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
),
KeywordSummary AS (
    SELECT mk.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT ms.movie_id,
       ms.title,
       ms.production_year,
       COALESCE(ps.person_role, 'Unknown') AS role,
       COALESCE(ps.role_count, 0) AS role_count,
       ms.cast_count,
       ms.avg_info_exists,
       ks.keywords,
       CASE 
           WHEN ms.long_title_flag = 1 THEN 'Long Title'
           ELSE 'Short Title'
       END AS title_length_category
FROM MovieStats ms
LEFT JOIN PersonRoles ps ON ms.movie_id = ps.movie_id
LEFT JOIN KeywordSummary ks ON ms.movie_id = ks.movie_id
ORDER BY ms.production_year DESC, ms.cast_count DESC
LIMIT 100;
