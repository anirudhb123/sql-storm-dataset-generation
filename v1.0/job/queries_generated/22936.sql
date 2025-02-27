WITH Recursive_Title_Paths AS (
    SELECT t.id AS title_id, 
           t.title AS title_name, 
           CAST(t.title AS text) AS full_path,
           1 AS depth
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT t.id,
           t.title,
           CONCAT(r.full_path, ' -> ', t.title),
           r.depth + 1
    FROM title t
    JOIN movie_link ml ON ml.movie_id = r.title_id
    JOIN title r ON ml.linked_movie_id = r.id
    WHERE t.production_year >= 2000 AND r.depth < 5
),

Filtered_Cast AS (
    SELECT ci.movie_id, 
           COUNT(DISTINCT ci.person_id) AS actor_count,
           STRING_AGG(ka.name, ', ') AS actors
    FROM cast_info ci
    JOIN aka_name ka ON ka.person_id = ci.person_id
    WHERE ci.nr_order IS NOT NULL
    GROUP BY ci.movie_id
),

Movie_Info AS (
    SELECT mi.movie_id,
           MAX(CASE WHEN it.info = 'summary' THEN mi.info END) AS summary,
           MAX(CASE WHEN it.info = 'tagline' THEN mi.info END) AS tagline
    FROM movie_info mi
    JOIN info_type it ON it.id = mi.info_type_id
    GROUP BY mi.movie_id
),

Ranked_Movies AS (
    SELECT rt.title_id, 
           rt.title_name,
           COALESCE(fi.actor_count, 0) AS actor_count, 
           mi.summary,
           mi.tagline,
           RANK() OVER (PARTITION BY rt.depth ORDER BY COALESCE(fi.actor_count, 0) DESC) AS rank
    FROM Recursive_Title_Paths rt
    LEFT JOIN Filtered_Cast fi ON fi.movie_id = rt.title_id
    LEFT JOIN Movie_Info mi ON mi.movie_id = rt.title_id
)

SELECT *,
       CASE 
           WHEN rank <= 3 THEN 'Top Ranked'
           WHEN rank <= 10 THEN 'Mid Ranked'
           ELSE 'Low Ranked'
       END AS rank_category,
       CASE 
           WHEN summary IS NULL THEN 'No Summary Available'
           ELSE summary
       END AS final_summary,
       LENGTH(tagline) AS tagline_length
FROM Ranked_Movies
WHERE actor_count > 0
ORDER BY title_name, rank;
