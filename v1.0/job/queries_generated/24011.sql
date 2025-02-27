WITH recursive Actor_Movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
Filtered_Movies AS (
    SELECT
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM 
        Actor_Movies
    WHERE 
        year_rank <= 5
),
Top_Actors AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        Filtered_Movies
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(movie_title) > 3
),
CoActors AS (
    SELECT
        fa.actor_id AS actor_id,
        ca.actor_id AS co_actor_id,
        COUNT(DISTINCT ci2.movie_id) AS common_movies_count
    FROM 
        Filtered_Movies fa
    JOIN 
        cast_info ci1 ON fa.movie_title = (
            SELECT t.title 
            FROM aka_title t 
            WHERE t.production_year = fa.production_year
              AND t.title IS NOT NULL
            LIMIT 1
        )
    JOIN 
        cast_info ci2 ON ci1.movie_id = ci2.movie_id
    JOIN 
        Filtered_Movies ca ON ci2.person_id = ca.actor_id
    WHERE 
        fa.actor_id <> ca.actor_id
    GROUP BY 
        fa.actor_id, ca.actor_id
    HAVING 
        COUNT(DISTINCT ci2.movie_id) > 2
),
Movie_Stats AS (
    SELECT 
        title.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(m.production_year) AS avg_year
    FROM 
        aka_title title
    JOIN 
        cast_info ci ON ci.movie_id = title.id
    LEFT JOIN 
        movie_info m ON title.id = m.movie_id
    GROUP BY 
        title.title
)
SELECT 
    a.actor_name,
    COALESCE(ca.common_movies_count, 0) AS co_actor_common_movies,
    ms.cast_count,
    ms.avg_year
FROM 
    Top_Actors a
LEFT JOIN 
    CoActors ca ON a.actor_id = ca.actor_id
JOIN 
    Movie_Stats ms ON EXISTS (
        SELECT 1
        FROM Filtered_Movies fm
        WHERE fm.actor_id = a.actor_id
          AND fm.movie_title = ms.movie_title
    )
ORDER BY 
    co_actor_common_movies DESC,
    a.actor_name;

This query performs the following actions:

1. **Recursive CTE**: The `Actor_Movies` CTE retrieves actors and their movies, ordering them by production year for the purposes of ranking.
2. **Filtering and Aggregation**: The `Filtered_Movies` CTE restricts results to actors with their top 5 recent films.
3. **Count of Movies**: The `Top_Actors` CTE counts the number of movies each actor appeared in and filters for those who have more than 3 movies.
4. **Co-Actors**: The `CoActors` CTE finds common movies shared between actors and counts them.
5. **Movie Statistics**: The `Movie_Stats` CTE calculates the cast count and average year of production for each movie.
6. **Final Selection**: The main query selects actor names alongside their common movie count with co-actors and movie statistics, including a NULL check with COALESCE to handle missing values.

These interactions provide insight into actor collaborations, roles, and movie statistics, showcasing various SQL constructs such as window functions, outer joins, recursive queries, and complex aggregations.
