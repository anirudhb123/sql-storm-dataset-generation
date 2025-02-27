WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(ci.id) AS actor_count,
        RANK() OVER (PARTITION BY mt.id ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title AS mt
    JOIN 
        movie_companies AS mc ON mc.movie_id = mt.id
    JOIN 
        cast_info AS ci ON ci.movie_id = mt.id
    JOIN 
        aka_name AS ak ON ak.person_id = ci.person_id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ARRAY_AGG(DISTINCT rm.actor_name) AS actors,
        MAX(rm.actor_count) AS total_actors
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.rank = 1
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.total_actors,
    ki.keywords
FROM 
    MovieDetails AS md
LEFT JOIN 
    KeywordInfo AS ki ON md.movie_id = ki.movie_id
ORDER BY 
    md.production_year DESC, 
    md.total_actors DESC;