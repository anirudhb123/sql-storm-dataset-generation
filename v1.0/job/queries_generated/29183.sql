WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),

ActorStats AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT m.title) AS movies,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id 
    JOIN 
        aka_title m ON ci.movie_id = m.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        p.id, p.name
),

FinalReport AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        a.actor_name,
        a.movie_count,
        a.movies,
        a.keywords
    FROM 
        RankedMovies rm
    JOIN 
        ActorStats a ON rm.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = a.person_id) 
    WHERE 
        rm.year_rank <= 3  -- Limit to top 3 highest production years per kind
)

SELECT 
    movie_title,
    production_year,
    actor_name,
    movie_count,
    movies,
    keywords
FROM 
    FinalReport
ORDER BY 
    production_year DESC, movie_title;
