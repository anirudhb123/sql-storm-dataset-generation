WITH MovieStatistics AS (
    SELECT 
        t.title AS movie_title, 
        a.name AS actor_name, 
        COUNT(DISTINCT c.id) AS number_of_cast_members,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(m.id) AS number_of_companies,
        MIN(m.production_year) AS earliest_year,
        MAX(m.production_year) AS latest_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    GROUP BY 
        t.id, a.name
),
ActorStatistics AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT cs.movie_id) AS starred_movies,
        STRING_AGG(DISTINCT ti.title, ', ') AS movie_titles,
        MAX(cs.nr_order) AS highest_role_order
    FROM 
        aka_name a
    JOIN 
        cast_info cs ON a.person_id = cs.person_id
    JOIN 
        aka_title ti ON cs.movie_id = ti.id
    GROUP BY
        a.name
)
SELECT 
    ms.movie_title,
    ms.actor_name,
    ms.number_of_cast_members,
    ms.keywords,
    ms.number_of_companies,
    ms.earliest_year,
    ms.latest_year,
    asb.starred_movies,
    asb.movie_titles,
    asb.highest_role_order
FROM 
    MovieStatistics ms
JOIN 
    ActorStatistics asb ON ms.actor_name = asb.actor_name
WHERE 
    ms.latest_year > 2000
ORDER BY 
    ms.number_of_cast_members DESC,
    asb.starred_movies DESC;
