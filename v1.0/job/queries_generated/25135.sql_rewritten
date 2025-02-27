WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS cast_rank
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        cast_rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.keyword_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ARRAY_AGG(DISTINCT ci.kind) AS company_types
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
    LEFT JOIN 
        cast_info ci2 ON tm.movie_id = ci2.movie_id
    LEFT JOIN 
        aka_name a ON ci2.person_id = a.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.keyword_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.keyword_count,
    STRING_AGG(DISTINCT md.actor_names::text, ', ') AS actor_list,
    STRING_AGG(DISTINCT md.company_types::text, ', ') AS company_type_list
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count, md.keyword_count
ORDER BY 
    md.cast_count DESC, md.keyword_count DESC;