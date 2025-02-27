WITH Movie_Stats AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        AVG(m.production_year) AS avg_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title
),
Popular_Movies AS (
    SELECT 
        ms.movie_id,
        ms.movie_title,
        ms.actor_count,
        ms.keyword_count,
        ms.avg_year
    FROM 
        Movie_Stats ms
    WHERE 
        ms.actor_count > 10 AND ms.keyword_count > 5
),
Top_Actors AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movies_played
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    WHERE 
        c.person_role_id IN (SELECT id FROM role_type WHERE role = 'actor')
    GROUP BY 
        c.person_id, a.name
    ORDER BY 
        movies_played DESC
    LIMIT 10
)
SELECT 
    pm.movie_title,
    pm.actor_count,
    pm.keyword_count,
    t.actor_name,
    ta.movies_played
FROM 
    Popular_Movies pm
JOIN 
    Top_Actors ta ON ta.movies_played > pm.actor_count
ORDER BY 
    pm.actor_count DESC, pm.keyword_count DESC;

This query accomplishes the following:

1. It computes the statistics for movies produced after the year 2000, counting the number of distinct actors and distinct keywords associated with each movie.
2. It identifies 'popular' movies with more than 10 actors and more than 5 keywords.
3. It calculates the top 10 actors based on the number of movies they've played in.
4. Finally, it joins the popular movies with the top actors to show which top actors participated in these popular films, sorted by the count of actors and keywords.
