WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        row_number() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorCTE AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(c.nr_order, 999) AS actor_order
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
),
CompanyCTE AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        movie_info AS m ON mc.movie_id = m.movie_id
    WHERE 
        m.info_type_id IS NOT NULL
    GROUP BY 
        m.movie_id
),
MoviesWithDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        a.actor_name,
        a.actor_order,
        c.company_count,
        c.companies
    FROM 
        MovieCTE AS m
    LEFT JOIN 
        ActorCTE AS a ON m.movie_id = a.movie_id
    LEFT JOIN 
        CompanyCTE AS c ON m.movie_id = c.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    actor_order,
    company_count,
    companies
FROM 
    MoviesWithDetails
WHERE 
    (production_year = 2020 OR production_year IS NULL)
    AND company_count > 0
ORDER BY 
    production_year DESC, 
    rn, 
    actor_order;
