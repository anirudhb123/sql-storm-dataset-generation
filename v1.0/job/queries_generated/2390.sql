WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        k.keyword,
        ARRAY_AGG(DISTINCT an.name) AS actor_names,
        COALESCE(
            AVG(CASE WHEN mi.info_type_id = 1 THEN mi.info::numeric END), 0
        ) AS average_rating
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.subject_id = an.person_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, k.keyword
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_names::text, ', ') AS actors,
    md.keyword,
    md.average_rating
FROM 
    MovieDetails md
WHERE 
    md.average_rating IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.keyword
ORDER BY 
    md.production_year DESC, 
    md.average_rating DESC;
