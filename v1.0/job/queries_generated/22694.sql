WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
), 
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year <= 5
), 
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ac.name AS actor_name,
        ac.id AS actor_id,
        k.keyword AS movie_keyword,
        COALESCE(mn.info, 'No info available') AS movie_info
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ac ON ci.person_id = ac.person_id 
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Short plot')
    LEFT JOIN 
        movie_info_idx mn ON tm.movie_id = mn.movie_id AND mn.info_type_id = (SELECT id FROM info_type WHERE info = 'Tagline')
), 
AggregatedInfo AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(DISTINCT CONCAT(actor_name, ' (ID: ', actor_id, ')'), '; ') AS actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(movie_info) AS relevant_info
    FROM 
        MovieDetails
    GROUP BY 
        title, production_year
)
SELECT 
    title,
    production_year,
    actors,
    keywords,
    relevant_info
FROM 
    AggregatedInfo
WHERE 
    keywords IS NOT NULL AND relevant_info IS NOT NULL
ORDER BY 
    production_year DESC, title ASC;
