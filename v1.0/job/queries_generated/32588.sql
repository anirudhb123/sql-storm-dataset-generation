WITH RECURSIVE ActorHierarchy AS (
    SELECT a.id AS actor_id, a.person_id, a.name, 1 AS level
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT a.id, a.person_id, a.name, ah.level + 1
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN ActorHierarchy ah ON ci.movie_id IN (
        SELECT linked_movie_id 
        FROM movie_link 
        WHERE movie_id = ah.actor_id
    )
),
MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mc.company_id,
        c.name AS company_name,
        COUNT(DISTINCT ch.id) AS char_count,
        AVG(CASE WHEN ch.name IS NOT NULL THEN 1 ELSE 0 END) AS average_character_names,
        COUNT(ki.id) AS keyword_count
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN char_name ch ON cc.subject_id = ch.id
    LEFT JOIN movie_keyword ki ON mt.id = ki.movie_id
    GROUP BY mt.title, mt.production_year, mc.company_id, c.name
),
FinalResults AS (
    SELECT 
        ad.actor_id,
        ad.name AS actor_name,
        md.movie_title,
        md.production_year,
        md.company_name,
        md.char_count,
        md.average_character_names,
        md.keyword_count,
        DENSE_RANK() OVER (PARTITION BY md.production_year ORDER BY md.char_count DESC) AS rank_by_char_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS row_num
    FROM ActorHierarchy ad
    JOIN MovieDetails md ON md.company_id IN (
        SELECT mc.company_id 
        FROM movie_companies mc 
        WHERE mc.movie_id IN (
            SELECT ci.movie_id 
            FROM cast_info ci 
            WHERE ci.person_id = ad.person_id
        )
    )
)

SELECT 
    fa.actor_name,
    fa.movie_title,
    fa.production_year,
    fa.company_name,
    fa.char_count,
    fa.average_character_names,
    fa.keyword_count,
    fa.rank_by_char_count,
    fa.row_num
FROM FinalResults fa
WHERE fa.rank_by_char_count <= 5 AND fa.production_year IS NOT NULL
ORDER BY fa.production_year, fa.char_count DESC;
