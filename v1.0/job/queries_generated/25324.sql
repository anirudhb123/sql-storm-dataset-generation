WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
), 
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies
    FROM 
        RankedTitles
    WHERE 
        actor_rank <= 5
    GROUP BY 
        actor_name
), 
KeywordCount AS (
    SELECT 
        t.id AS movie_id,
        k.keyword,
        COUNT(k.keyword) AS keyword_frequency
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, k.keyword
), 
KeywordStatistics AS (
    SELECT 
        keyword,
        AVG(keyword_frequency) AS avg_frequency,
        MAX(keyword_frequency) AS max_frequency,
        MIN(keyword_frequency) AS min_frequency
    FROM 
        KeywordCount
    GROUP BY 
        keyword
)
SELECT 
    ac.actor_name,
    ac.total_movies,
    ks.keyword,
    ks.avg_frequency,
    ks.max_frequency,
    ks.min_frequency
FROM 
    ActorCount ac
JOIN 
    KeywordStatistics ks ON ac.total_movies > 10
ORDER BY 
    ac.total_movies DESC, ks.avg_frequency DESC;

This SQL query benchmarks string processing by analyzing actor participation in movies produced after the year 2000, while also considering the frequency of keywords associated with those titles. It ranks actors based on their movie roles, counts their appearances and extracts keyword statistics, providing a comprehensive overview of screen presence and thematic elements in contemporary cinema.
