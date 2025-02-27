WITH Movie_Info AS (
    SELECT mt.movie_id, 
           mt.title, 
           mt.production_year,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           COUNT(DISTINCT c.person_id) AS cast_count
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE mt.production_year >= 2000
    GROUP BY mt.movie_id, mt.title, mt.production_year
),
Top_Movies AS (
    SELECT mi.movie_id,
           mi.title,
           mi.production_year,
           mi.keywords,
           mi.cast_count,
           ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.cast_count DESC) AS rank
    FROM Movie_Info mi
)
SELECT tm.title, 
       tm.production_year,
       tm.keywords,
       COALESCE(ct.kind, 'Unknown') AS company_type,
       COALESCE((SELECT COUNT(*) 
                 FROM movie_companies mc 
                 WHERE mc.movie_id = tm.movie_id 
                 AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')), 0) AS distributor_count
FROM Top_Movies tm
LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
WHERE tm.rank <= 5
ORDER BY tm.production_year DESC, tm.cast_count DESC;
