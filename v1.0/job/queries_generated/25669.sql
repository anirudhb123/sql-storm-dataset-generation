WITH TitleKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        k.phonetic_code
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND k.keyword LIKE 'Action%'
), 
ActorDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.gender,
        a.imdb_id AS actor_imdb_id
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        p.gender = 'M'
), 
MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        ratings r ON m.id = r.movie_id
    GROUP BY 
        m.id
) 
SELECT 
    t.title,
    a.actor_name,
    a.gender,
    t.keyword,
    r.average_rating
FROM 
    TitleKeywords t
JOIN 
    ActorDetails a ON t.movie_id = a.movie_id
JOIN 
    MovieRatings r ON t.movie_id = r.movie_id
WHERE 
    r.average_rating IS NOT NULL
ORDER BY 
    t.title, 
    a.actor_name;

This query does the following:
1. It creates a Common Table Expression (CTE) named `TitleKeywords` to filter movies from the `aka_title` table that were produced after the year 2000 and have keywords that start with "Action".
2. It then constructs another CTE named `ActorDetails`, which retrieves details about actors from `cast_info` alongside actor names and their corresponding gender.
3. It constructs yet another CTE named `MovieRatings` calculating the average rating for each movie using a hypothetical `ratings` table (which you may need to create separately if not available).
4. Finally, it selects the movie titles, actor names, genders, keywords, and average ratings, ensuring that there are valid ratings associated with the movies and orders the results alphabetically by title and actor name.
