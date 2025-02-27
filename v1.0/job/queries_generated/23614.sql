WITH Recursive_Aka AS (
    SELECT 
        ak.id AS aka_id,
        ak.person_id,
        ak.name,
        ak.imdb_index,
        ak.name_pcode_cf,
        ak.name_pcode_nf,
        ak.surname_pcode,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.id) as row_num
    FROM aka_name ak
    WHERE ak.name IS NOT NULL AND ak.name <> ''
), 

Person_Roles AS (
    SELECT 
        ci.person_id,
        r.role,
        COUNT(*) as role_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.person_id, r.role
    HAVING COUNT(*) > 1
    ORDER BY role_count DESC
),

Movie_Episode_Info AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.season_nr ORDER BY mt.episode_nr) as episode_position
    FROM aka_title mt
    WHERE mt.season_nr IS NOT NULL
),

NULL_Logics AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(m.title, 'Untitled') as title,
        COALESCE(c.person_id, -1) as actor_id,
        ci.note as cast_note,
        CASE 
            WHEN ci.note IS NOT NULL THEN 'Noteworthy'
            ELSE 'No Note'
        END as note_status
    FROM Movie_Episode_Info m
    LEFT JOIN cast_info ci ON m.movie_id = ci.movie_id
)

SELECT 
    ra.name AS actor_name,
    ra.imdb_index AS actor_index,
    ra.row_num,
    pei.title AS movie_title,
    pei.production_year,
    pei.episode_position,
    nli.note_status,
    r.role,
    r.role_count
FROM Recursive_Aka ra
INNER JOIN Person_Roles r ON ra.person_id = r.person_id
LEFT JOIN NULL_Logics nli ON ra.id = nli.actor_id
INNER JOIN Movie_Episode_Info pei ON nli.movie_id = pei.movie_id
WHERE 
    pei.production_year BETWEEN 2000 AND 2025
    AND (nli.cast_note IS NULL OR nli.cast_note LIKE '%important%')
ORDER BY r.role_count DESC, pei.episode_position ASC;

-- Combining various aspects of the Join Order Benchmark schema while ensuring to cover outer joins, CTEs, window functions, 
-- complicated predicates, and NULL logic, allowing performance benchmarks to assess the execution strategy used by the SQL engine.
