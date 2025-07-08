
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM title t
),
PersonInfo AS (
    SELECT 
        p.id AS person_id,
        ak.name AS aka_name,
        pi.info AS person_info
    FROM aka_name ak
    JOIN name p ON ak.person_id = p.id
    LEFT JOIN person_info pi ON p.id = pi.person_id
    WHERE pi.info_type_id IS NULL OR pi.info_type_id IN (
        SELECT id FROM info_type WHERE info ILIKE '%actor%'
    )
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget
    FROM aka_title m
    JOIN cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY m.id, m.title
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.actor_count,
        mt.total_budget
    FROM MovieInfo mt
    WHERE mt.actor_count > 5 AND mt.total_budget > 1000000
),
ComplicatedJoin AS (
    SELECT 
        f.title AS movie_title,
        p.aka_name,
        f.actor_count,
        f.total_budget,
        CASE 
            WHEN f.total_budget IS NULL THEN 'No Budget Information'
            WHEN f.total_budget = 0 THEN 'Budget Not Specified'
            ELSE 'Budget Available'
        END AS budget_status
    FROM FilteredMovies f
    LEFT JOIN PersonInfo p ON f.movie_id IN (
        SELECT DISTINCT c.movie_id FROM cast_info c WHERE c.person_id = p.person_id
    )
)
SELECT 
    cj.movie_title,
    LISTAGG(DISTINCT cj.aka_name, ', ') WITHIN GROUP (ORDER BY cj.aka_name) AS actors,
    cj.actor_count,
    cj.total_budget,
    cj.budget_status,
    COALESCE(rt.title_count, 0) AS titles_per_year
FROM ComplicatedJoin cj
LEFT JOIN RankedTitles rt ON rt.production_year = (
    SELECT DISTINCT mt.production_year FROM aka_title mt WHERE mt.title = cj.movie_title
)
GROUP BY 
    cj.movie_title, 
    cj.actor_count, 
    cj.total_budget, 
    cj.budget_status,
    rt.title_count
ORDER BY 
    cj.total_budget DESC, 
    cj.actor_count DESC;
