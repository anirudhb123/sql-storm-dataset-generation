WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        t.production_year > 2000
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        pa.actor_name, 
        kc.keyword
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        PopularActors pa ON ci.person_id = (SELECT person_id FROM aka_name WHERE name = pa.actor_name LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
)
SELECT 
    md.title, 
    md.production_year, 
    md.actor_name, 
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
FROM 
    MovieDetails md
GROUP BY 
    md.title, 
    md.production_year, 
    md.actor_name
ORDER BY 
    md.production_year DESC, 
    md.title;
