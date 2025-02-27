WITH RECURSIVE CastHierarchy AS (
    SELECT ci.movie_id, ci.person_id, 1 AS level
    FROM cast_info ci
    WHERE ci.person_role_id IS NOT NULL

    UNION ALL

    SELECT ci2.movie_id, ci2.person_id, ch.level + 1
    FROM cast_info ci2
    JOIN CastHierarchy ch ON ci2.movie_id = ch.movie_id
    WHERE ci2.person_id <> ch.person_id
),
AggregatedCast AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS total_actors,
           MAX(level) AS max_cast_level
    FROM CastHierarchy
    GROUP BY movie_id
),
TitleDetails AS (
    SELECT t.id AS title_id,
           t.title,
           t.production_year,
           a.name AS director_name
    FROM title t
    LEFT JOIN aka_name a ON a.person_id = (
        SELECT ci.person_id
        FROM cast_info ci
        WHERE ci.movie_id = t.id AND ci.role_id = (
            SELECT id FROM role_type WHERE role = 'director'
        )
        LIMIT 1
    )
),
MovieKeywords AS (
    SELECT mk.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FinalReport AS (
    SELECT td.title,
           td.production_year,
           ac.total_actors,
           ac.max_cast_level,
           COALESCE(mk.keywords, 'No Keywords') AS keywords,
           CASE
               WHEN ac.total_actors > 50 THEN 'Large Ensemble'
               WHEN ac.total_actors BETWEEN 20 AND 50 THEN 'Medium Ensemble'
               ELSE 'Small Ensemble'
           END AS ensemble_size
    FROM TitleDetails td
    JOIN AggregatedCast ac ON td.title_id = ac.movie_id
    LEFT JOIN MovieKeywords mk ON td.title_id = mk.movie_id
)
SELECT *
FROM FinalReport
ORDER BY production_year DESC, total_actors DESC;
