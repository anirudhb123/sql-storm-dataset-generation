WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        TopMovies tm
    JOIN 
        aka_title t ON tm.title = t.title AND tm.production_year = t.production_year
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id AND mi.info_type_id = 1
    GROUP BY 
        t.title, t.production_year, mi.info
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.keywords,
    md.movie_info
FROM 
    MovieDetails md
WHERE 
    md.keywords IS NOT NULL
    AND md.actor_names NOT LIKE '%John%'
ORDER BY 
    md.production_year DESC, md.title;
