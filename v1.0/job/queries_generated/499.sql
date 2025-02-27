WITH MovieRankings AS (
    SELECT 
        at.title, 
        COUNT(DISTINCT cc.person_id) AS actor_count,
        SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS role_note_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_within_year
    FROM aka_title at
    LEFT JOIN cast_info cc ON at.movie_id = cc.movie_id
    GROUP BY at.movie_id, at.title, at.production_year
),
SelectedMovies AS (
    SELECT 
        title,
        actor_count,
        role_note_count
    FROM MovieRankings
    WHERE actor_count > 5 
      AND rank_within_year <= 10
)
SELECT 
    sm.title, 
    sm.actor_count, 
    sm.role_note_count, 
    CASE 
        WHEN sm.role_note_count IS NULL THEN 'No Notes' 
        WHEN sm.role_note_count > 0 THEN 'Has Notes' 
        ELSE 'Unknown' 
    END AS note_status
FROM SelectedMovies sm
JOIN movie_info mi ON mi.movie_id = (SELECT m.movie_id FROM aka_title m WHERE m.title = sm.title LIMIT 1)
LEFT JOIN company_name cn ON cn.id = (SELECT mc.company_id FROM movie_companies mc WHERE mc.movie_id = (SELECT m.movie_id FROM aka_title m WHERE m.title = sm.title LIMIT 1) LIMIT 1)
WHERE cn.country_code IS NOT NULL
ORDER BY sm.actor_count DESC, sm.title ASC;
