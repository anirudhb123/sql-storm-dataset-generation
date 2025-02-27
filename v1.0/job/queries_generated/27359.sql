WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(c.kind, 'Unknown') AS movie_kind,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        AVG(mi.info_length) AS average_info_length
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            LENGTH(info) AS info_length 
        FROM 
            movie_info 
        WHERE 
            info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
    ) mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),

FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        movie_kind,
        production_year,
        cast_count,
        average_info_length,
        RANK() OVER (PARTITION BY movie_kind ORDER BY average_info_length DESC) AS kind_rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND 
        cast_count > 5
)

SELECT 
    movie_id,
    title,
    movie_kind,
    production_year,
    cast_count,
    average_info_length
FROM 
    FilteredMovies
WHERE 
    kind_rank <= 3
ORDER BY 
    movie_kind, average_info_length DESC;
