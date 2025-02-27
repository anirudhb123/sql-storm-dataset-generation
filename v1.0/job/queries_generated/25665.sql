WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year >= 2000 
), actor_statistics AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies,
        AVG(production_year) AS avg_production_year
    FROM 
        ranked_movies
    GROUP BY 
        actor_name
), movie_keywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
), keyword_summary AS (
    SELECT 
        keyword,
        COUNT(movie_title) AS movie_count
    FROM 
        movie_keywords
    GROUP BY 
        keyword
    HAVING 
        COUNT(movie_title) > 5
)
SELECT 
    as.actor_name,
    as.total_movies,
    as.avg_production_year,
    group_concat(ks.keyword) AS keywords
FROM 
    actor_statistics as
LEFT JOIN 
    keyword_summary ks ON as.total_movies > 3
GROUP BY 
    as.actor_name, as.total_movies, as.avg_production_year
ORDER BY 
    as.total_movies DESC, as.avg_production_year ASC;

This SQL query performs the following tasks:

1. **ranked_movies**: It identifies movies released from the year 2000 onward and ranks the actors associated with each movie based on their order in the cast list.

2. **actor_statistics**: It compiles statistics for each actor, including the total number of movies they have participated in and the average production year of those movies.

3. **movie_keywords**: It gathers the keywords associated with movies produced from the year 2000 onward.

4. **keyword_summary**: This aggregates keywords that appear in more than 5 movies, focusing on frequently associated themes with the movies.

5. Finally, the main query combines statistics on actors with significant experience (more than three movies), along with a concatenated list of their associated keywords, and orders the results by total movie count and average production year.
