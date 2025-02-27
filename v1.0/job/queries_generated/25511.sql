WITH RankedMovies AS (
    SELECT 
        tit.title AS movie_title,
        tit.production_year,
        GROUP_CONCAT(DISTINCT aka.name ORDER BY aka.name SEPARATOR ', ') AS actors,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY tit.production_year ORDER BY COUNT(DISTINCT kw.keyword) DESC) AS year_rank
    FROM 
        title AS tit
    JOIN 
        movie_companies AS mc ON tit.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        complete_cast AS cc ON tit.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name AS aka ON ci.person_id = aka.person_id
    LEFT JOIN 
        movie_keyword AS mk ON tit.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        cn.country_code = 'USA' AND
        tit.production_year >= 2000
    GROUP BY 
        tit.title, tit.production_year
), 

TopActors AS (
    SELECT 
        actor.name AS actor_name,
        COUNT(DISTINCT rc.movie_title) AS movie_count
    FROM 
        RankedMovies AS rc
    JOIN 
        AKA_name AS actor ON actor.name IN (SELECT name FROM RankedMovies GROUP BY movie_title HAVING year_rank <= 5)
    GROUP BY 
        actor.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_title, 
    rm.production_year,
    rm.actors,
    ta.actor_name,
    ta.movie_count
FROM 
    RankedMovies AS rm
JOIN 
    TopActors AS ta ON rm.actors LIKE CONCAT('%', ta.actor_name, '%')
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC;
This query does the following:

1. Creates a Common Table Expression (CTE) `RankedMovies` that collects movie titles, their production years, a list of actors, and counts distinct keywords for movies produced in the USA from 2000 onwards. It also ranks these movies by the number of keywords.
  
2. Another CTE `TopActors` selects the top 10 actors based on their count of appearances in the movies selected in `RankedMovies`.

3. Finally, it retrieves movie titles, their production years, actor names, and counts for the top actors who featured in these films, ordered by production year and the number of distinct keywords.
