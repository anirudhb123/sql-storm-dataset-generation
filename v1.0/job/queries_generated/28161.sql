WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_type,
        COUNT(DISTINCT c.id) AS total_cast_members
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, t.title, t.production_year, r.role
),
most_prolific_actors AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        movie_actors
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
movies_with_keywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS associated_keyword,
        t.production_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
keyword_summary AS (
    SELECT 
        mwk.movie_title,
        STRING_AGG(mwk.associated_keyword, ', ') AS keywords_list
    FROM 
        movies_with_keywords mwk
    GROUP BY 
        mwk.movie_title
)
SELECT 
    mp.actor_name,
    mp.movie_count,
    kw.keywords_list,
    unique_movies.production_year
FROM 
    most_prolific_actors mp
JOIN 
    keyword_summary kw ON kw.movie_title IN (
        SELECT movie_title 
        FROM movie_actors ma WHERE ma.actor_name = mp.actor_name
    )
JOIN 
    movie_actors unique_movies ON unique_movies.actor_name = mp.actor_name
ORDER BY 
    mp.movie_count DESC, unique_movies.production_year DESC;
