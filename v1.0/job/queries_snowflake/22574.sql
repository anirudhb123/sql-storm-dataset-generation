
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        kt.kind AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(ci.role_id) OVER (PARTITION BY mt.id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        kind_type kt ON mt.kind_id = kt.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL
        AND mt.production_year > 2000
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        movie_kind,
        cast_count,
        COALESCE(cast_count, 0) AS actual_cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
),
FilteredMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.movie_kind,
        tm.cast_count
    FROM 
        TopMovies tm
    WHERE 
        tm.cast_count > 5
    ORDER BY 
        tm.production_year DESC
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        rt.role AS actor_role,
        COUNT(ci.id) AS roles_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
    HAVING 
        COUNT(ci.id) > 2
),
FinalResults AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.movie_kind,
        fm.cast_count,
        cs.actor_role,
        cs.roles_count,
        CONCAT(fm.title, ' - ', cs.actor_role) AS title_with_role
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CastStatistics cs ON fm.title = (SELECT mt.title FROM aka_title mt WHERE mt.id = cs.movie_id LIMIT 1)
)
SELECT 
    fr.title_with_role,
    fr.production_year,
    fr.movie_kind,
    fr.cast_count,
    COALESCE(fr.roles_count, 0) AS total_roles,
    CONCAT('A total of ', COALESCE(fr.roles_count, 0), ' roles were played in ', fr.title) AS role_message
FROM 
    FinalResults fr
WHERE 
    fr.cast_count > 10
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC
LIMIT 50;
