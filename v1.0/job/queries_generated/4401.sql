WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        r.role AS actor_role,
        COALESCE(SUM(m.movie_link_count), 0) AS movie_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        (SELECT 
            movie_id,
            COUNT(linked_movie_id) AS movie_link_count
         FROM 
            movie_link
         GROUP BY 
            movie_id) AS m ON ci.movie_id = m.movie_id
    GROUP BY 
        p.id, p.name, r.role
),
FinalReport AS (
    SELECT 
        tm.title,
        tm.production_year,
        ad.name AS actor_name,
        ad.actor_role,
        ad.movie_count
    FROM 
        TopMovies tm
    JOIN 
        ActorDetails ad ON ad.person_id IN (
            SELECT person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = (
                SELECT id 
                FROM aka_title 
                WHERE title = tm.title AND production_year = tm.production_year
            )
        )
)
SELECT 
    title,
    production_year,
    actor_name,
    actor_role,
    movie_count
FROM 
    FinalReport
WHERE 
    movie_count > 2
ORDER BY 
    production_year DESC, 
    title ASC;
