WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title t ON mk.movie_id = t.id
    GROUP BY 
        t.id
),
DetailedInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        mk.keywords,
        COUNT(DISTINCT ci.id) AS total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = (SELECT id FROM title WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1)
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM title WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1)
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        rm.movie_title, rm.production_year, rm.actor_name, mk.keywords
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    keywords,
    total_cast
FROM 
    DetailedInfo
WHERE 
    total_cast > 1
ORDER BY 
    production_year DESC, actor_name ASC;

