
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    JOIN 
        aka_title AS m ON c.movie_id = m.id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT m.movie_id) > 1
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies AS m
    JOIN 
        company_name AS co ON m.company_id = co.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ad.name AS leading_actor,
    ad.movie_count,
    mc.companies
FROM 
    RankedMovies AS rm
LEFT JOIN 
    ActorDetails AS ad ON ad.movie_count = (SELECT MAX(movie_count) FROM ActorDetails)
LEFT JOIN 
    MovieCompanies AS mc ON mc.movie_id = rm.movie_id
WHERE 
    rm.actor_count_rank = 1
ORDER BY 
    rm.production_year DESC, rm.title;
