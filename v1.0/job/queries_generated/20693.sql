WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id as movie_id, 
        m.title, 
        1 as level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        CONCAT(h.title, ' -> ', m.title),
        h.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role,
        COUNT(DISTINCT c.movie_id) as movie_count,
        COALESCE(SUM(CASE WHEN m.production_year < 2005 THEN 1 ELSE 0 END), 0) AS pre_2005_movies 
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        c.person_id, r.role
    HAVING 
        COUNT(DISTINCT c.movie_id) > 3 
        AND COALESCE(SUM(CASE WHEN m.production_year < 2005 THEN 1 ELSE 0 END), 0) > 0 
),
TopActors AS (
    SELECT 
        ak.name AS actor_name,
        ar.role,
        ar.movie_count,
        ar.pre_2005_movies
    FROM 
        ActorRoles ar
    JOIN 
        aka_name ak ON ak.person_id = ar.person_id
    WHERE 
        ak.name IS NOT NULL AND ar.pre_2005_movies > 2
),
FilteredMovies AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 1980 AND 2020
        AND (c.country_code IS NULL OR c.country_code = 'USA')
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT m.id) > 3
),
FinalResults AS (
    SELECT 
        tm.title,
        ta.actor_name,
        ta.role,
        tm.production_year,
        tm.company_count,
        ROW_NUMBER() OVER (PARTITION BY ta.role ORDER BY tm.production_year DESC) AS rn
    FROM 
        FilteredMovies tm
    JOIN 
        TopActors ta ON tm.id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
)
SELECT 
    f.title,
    f.actor_name,
    f.role,
    f.production_year,
    f.company_count,
    CASE 
        WHEN f.rn = 1 THEN 'Top Recent Movie'
        WHEN f.rn <= 5 THEN 'Top Recent Movies'
        ELSE 'Other Movies'
    END AS movie_rank
FROM 
    FinalResults f
WHERE 
    f.company_count IS NOT NULL
ORDER BY 
    f.production_year DESC, f.actor_name;
