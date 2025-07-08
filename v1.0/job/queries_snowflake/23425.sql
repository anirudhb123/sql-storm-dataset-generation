
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
), 
FilteredActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        ak.md5sum,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name ak
    LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
    GROUP BY ak.id, ak.name, ak.md5sum
    HAVING COUNT(DISTINCT ci.movie_id) > 5
), 
MovieInfoWithNotes AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mn.info, '; ') WITHIN GROUP (ORDER BY mn.info) AS info_notes
    FROM movie_info mi
    LEFT JOIN movie_info_idx mn ON mi.movie_id = mn.movie_id
    GROUP BY mi.movie_id
), 
LatestMovieInfo AS (
    SELECT 
        rt.title_id,
        rt.production_year,
        rt.title,
        mn.info_notes,
        CASE 
            WHEN rt.rank = 1 THEN 'Latest'
            ELSE 'Previous'
        END AS movie_status
    FROM RankedTitles rt
    JOIN MovieInfoWithNotes mn ON rt.title_id = mn.movie_id
)

SELECT 
    ft.name AS actor_name,
    COALESCE(lm.title, 'No Titles Found') AS movie_title,
    lm.production_year,
    lm.info_notes,
    lm.movie_status
FROM FilteredActors ft
LEFT JOIN LatestMovieInfo lm ON ft.movie_count = (
        SELECT COUNT(*)
        FROM cast_info ci
        WHERE ci.person_id = ft.actor_id
        AND ci.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year IS NOT NULL)
    )
WHERE ft.md5sum IS NOT NULL 
AND lm.movie_status = 'Latest'
ORDER BY ft.movie_count DESC, lm.production_year DESC;
