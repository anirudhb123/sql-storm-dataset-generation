WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.movie_id) DESC) AS movie_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        movie_rank <= 3
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        LISTAGG(DISTINCT tt.title, ', ') WITHIN GROUP (ORDER BY tt.title) AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopTitles tt ON ci.movie_id = tt.title_id
    GROUP BY 
        a.name
)
SELECT 
    actor_name,
    total_movies,
    movies
FROM 
    ActorDetails
ORDER BY 
    total_movies DESC, actor_name;
