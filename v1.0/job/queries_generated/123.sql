WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(MIN(cd.nr_order), 0) AS min_cast_order,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info cd ON t.id = cd.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorStatistics AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    LEFT JOIN 
        (SELECT person_id, movie_id, nr_order FROM cast_info WHERE nr_order > 2) ci ON c.movie_id = ci.movie_id
    GROUP BY 
        a.name
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.min_cast_order,
    r.keyword_count,
    a.name AS actor_name,
    a.movie_count,
    a.avg_role_order
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    ActorStatistics a ON r.min_cast_order > a.avg_role_order
WHERE 
    r.production_year >= 2000
ORDER BY 
    r.production_year DESC, 
    a.movie_count DESC, 
    a.name;
