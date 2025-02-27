WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(mi.info = 'Award Winning')::int AS average_award_status,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
    WHERE mt.production_year IS NOT NULL
    GROUP BY mt.id, mt.title
    HAVING COUNT(DISTINCT ci.person_id) > 5 AND AVG(mi.info = 'Award Winning') IS NOT NULL
), FilteredActors AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        ci.movie_id
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    WHERE ak.name_pcode_nf IS NOT NULL AND ak.name_pcode_cf IS NOT NULL
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        ra.actor_name,
        DENSE_RANK() OVER (PARTITION BY rm.movie_id ORDER BY ra.actor_name) AS actor_rank,
        CASE 
            WHEN rm.average_award_status = 1 THEN 'Award Winning'
            ELSE 'Not Award Winning'
        END AS award_status
    FROM RankedMovies rm
    JOIN FilteredActors ra ON rm.movie_id = ra.movie_id
)
SELECT 
    md.movie_title,
    STRING_AGG(md.actor_name, ', ' ORDER BY md.actor_rank) AS actor_names,
    md.award_status,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL) AS non_null_notes
FROM MovieDetails md
LEFT JOIN cast_info ci ON md.movie_id = ci.movie_id
WHERE md.award_status = 'Award Winning' OR (md.award_status = 'Not Award Winning' AND md.movie_id IN (
    SELECT movie_id 
    FROM movie_keyword 
    WHERE keyword_id IN (SELECT id FROM keyword WHERE phonetic_code LIKE '%XYZ%')
))
GROUP BY md.movie_title, md.award_status
ORDER BY COUNT(md.actor_name) DESC, md.movie_title ASC
LIMIT 10;
