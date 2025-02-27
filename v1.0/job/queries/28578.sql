WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),

TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        movie_keyword
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),

ActorDetails AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT tt.title || ' (' || tt.production_year || ')', ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopTitles tt ON ci.movie_id = tt.title_id
    GROUP BY 
        a.person_id, a.name
)

SELECT 
    ad.actor_name,
    ad.total_movies,
    ad.movie_titles
FROM 
    ActorDetails ad
ORDER BY 
    ad.total_movies DESC, 
    ad.actor_name
LIMIT 10;
