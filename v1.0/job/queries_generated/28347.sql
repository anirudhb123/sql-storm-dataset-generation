WITH movie_statistics AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title AS a
    JOIN complete_cast AS cc ON a.id = cc.movie_id
    JOIN cast_info AS c ON cc.subject_id = c.id
    LEFT JOIN aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN movie_keyword AS mk ON a.id = mk.movie_id
    LEFT JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY a.id
),
company_statistics AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies AS mc
    JOIN company_name AS cn ON mc.company_id = cn.id
    JOIN company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.total_cast,
    ms.actors,
    cs.companies,
    cs.company_types,
    CASE 
        WHEN ms.total_cast > 5 THEN 'Large Cast'
        WHEN ms.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM movie_statistics AS ms
LEFT JOIN company_statistics AS cs ON ms.movie_title = cs.movie_id
ORDER BY ms.production_year DESC, ms.total_cast DESC;
