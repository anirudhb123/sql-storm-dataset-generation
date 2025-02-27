WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.person_id) AS num_actors,
        STRING_AGG(DISTINCT ka.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), ActorInfo AS (
    SELECT 
        ka.id AS aka_id,
        ka.name,
        ka.imdb_index,
        pi.info AS actor_biography
    FROM 
        aka_name ka
    LEFT JOIN 
        person_info pi ON ka.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_actors,
        rm.actor_names,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.num_actors, rm.actor_names
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.num_actors,
    md.actor_names,
    md.keyword_count,
    md.keywords,
    md.company_types
FROM 
    MovieDetails md
WHERE 
    md.num_actors > 10
ORDER BY 
    md.production_year DESC, 
    md.num_actors DESC;
