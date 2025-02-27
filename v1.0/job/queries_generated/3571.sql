WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.movie_rank <= 5
),
ActorsWithRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role,
        t.title,
        t.production_year
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS ct ON ci.role_id = ct.id
    JOIN 
        complete_cast AS cc ON ci.movie_id = cc.movie_id
    JOIN 
        title AS t ON cc.movie_id = t.id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(STRING_AGG(DISTINCT awr.actor_name || ' (' || awr.role || ')', ', '), 'No Cast') AS actors
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    ActorsWithRoles AS awr ON fm.title = awr.title AND fm.production_year = awr.production_year
GROUP BY 
    fm.title_id, fm.title, fm.production_year
ORDER BY 
    fm.production_year DESC, fm.title;
