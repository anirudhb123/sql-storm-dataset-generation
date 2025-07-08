
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_index,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, m.imdb_index
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        rm.rank <= 20
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.actor_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
