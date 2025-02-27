WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.person_id, a.name
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.name AS actor_name,
        ar.roles,
        ar.movie_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorRoles ar ON ci.person_id = ar.person_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ar.name, ar.roles, ar.movie_count
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name,
        roles,
        movie_count,
        company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC NULLS LAST, title) AS ranked_movie
    FROM 
        MoviesWithRoles
    WHERE 
        company_count > 1 AND 
        production_year > 2000
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.roles,
    f.movie_count,
    f.company_count,
    CASE 
        WHEN f.ranked_movie BETWEEN 1 AND 5 THEN 'Top 5'
        WHEN f.ranked_movie BETWEEN 6 AND 10 THEN '6-10'
        ELSE 'Other'
    END AS rank_category
FROM 
    FilteredMovies f
WHERE 
    EXISTS (
        SELECT 1
        FROM aka_title at
        WHERE at.movie_id = f.movie_id
        AND at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
        AND at.production_year IS NOT NULL
    )
ORDER BY 
    f.production_year DESC, f.movie_count DESC, f.title;
