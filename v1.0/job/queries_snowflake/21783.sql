
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
ActorsWithRoles AS (
    SELECT 
        a.name AS actor_name,
        c.nr_order,
        r.role AS role_name,
        m.title AS movie_title,
        m.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
    JOIN 
        TopMovies m ON m.movie_id = c.movie_id
),
MovieActors AS (
    SELECT 
        movie_title,
        LISTAGG(DISTINCT actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actor_list,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        ActorsWithRoles
    GROUP BY 
        movie_title
)
SELECT 
    ma.movie_title, 
    ma.actor_list,
    ma.actor_count,
    CASE 
        WHEN ma.actor_count IS NULL THEN 'No actors found'
        ELSE 'Actors found'
    END AS actor_status,
    EXISTS(
        SELECT 1 
        FROM aka_title at 
        WHERE at.title LIKE '%' || SPLIT(ma.movie_title, ' ')[0] || '%'
    ) AS title_similarity,
    COALESCE(ma.actor_count / NULLIF(m.production_year - 2000, 0), 0) AS normalized_actor_count
FROM 
    MovieActors ma
JOIN 
    TopMovies m ON ma.movie_title = m.title
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ma.actor_count DESC, ma.movie_title;
