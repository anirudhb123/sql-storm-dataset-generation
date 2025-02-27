WITH MovieDetails AS (
    SELECT t.title, t.production_year, COUNT(DISTINCT c.person_id) AS actor_count,
           AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM aka_title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN company_name co ON co.id IN (
        SELECT mc.company_id FROM movie_companies mc 
        WHERE mc.movie_id = t.id AND mc.company_type_id IN (
            SELECT ct.id FROM company_type ct WHERE ct.kind = 'Production')
    )
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN role_type r ON r.id = c.role_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.title, t.production_year
),
RankedMovies AS (
    SELECT title, production_year, actor_count, has_note_ratio,
           ROW_NUMBER() OVER (ORDER BY actor_count DESC, production_year ASC) AS rank
    FROM MovieDetails
)
SELECT rm.title, rm.production_year, rm.actor_count,
       COALESCE(rm.has_note_ratio, 0) AS has_note_ratio,
       cn.name AS company_name
FROM RankedMovies rm
LEFT JOIN movie_companies mc ON mc.movie_id IN (
    SELECT movie_id FROM movie_companies WHERE company_type_id IS NOT NULL
)
LEFT JOIN company_name cn ON cn.id = mc.company_id
WHERE rm.has_note_ratio > 0.5
UNION ALL
SELECT 'N/A', NULL, 0, 1.0, 'Total Movies' AS company_name 
FROM RankedMovies
WHERE NOT EXISTS (SELECT 1 FROM RankedMovies);
