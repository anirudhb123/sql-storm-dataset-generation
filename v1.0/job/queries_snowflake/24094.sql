WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_persons,
        SUM(CASE WHEN r.role = 'actor' THEN 1 ELSE 0 END) AS actor_count,
        SUM(CASE WHEN r.role = 'director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        pr.total_persons,
        pr.actor_count,
        pr.director_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoles pr ON rm.title_id = pr.movie_id
    WHERE 
        rm.rank <= 3
)
SELECT 
    fm.title,
    COALESCE(fm.total_persons, 0) AS total_persons,
    COALESCE(fm.actor_count, 0) AS actor_count,
    COALESCE(fm.director_count, 0) AS director_count,
    CASE 
        WHEN fm.total_persons IS NULL THEN 'No cast information available'
        ELSE 'Data available'
    END AS cast_info_status
FROM 
    FilteredMovies fm
WHERE 
    (fm.actor_count > 5 OR fm.director_count > 1)
    AND fm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fm.production_year DESC, fm.title;

