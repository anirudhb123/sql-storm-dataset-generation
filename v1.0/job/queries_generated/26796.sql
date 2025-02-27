WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        rk.RANK() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank,
        k.keyword AS keyword
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature')
),
GroupedTitles AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        RankedTitles
    GROUP BY 
        movie_title, production_year
),
FinalResult AS (
    SELECT 
        g.movie_title,
        g.production_year,
        g.actors,
        g.keywords,
        COUNT(c.id) AS cast_count
    FROM 
        GroupedTitles g
    LEFT JOIN 
        complete_cast c ON g.movie_title = c.movie_id
    GROUP BY 
        g.movie_title, g.production_year, g.actors, g.keywords
)
SELECT 
    movie_title,
    production_year,
    actors,
    keywords,
    cast_count
FROM 
    FinalResult
ORDER BY 
    production_year DESC, movie_title;
