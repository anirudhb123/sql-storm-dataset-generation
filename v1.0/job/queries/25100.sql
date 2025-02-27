WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.cast_members,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title, m.production_year, m.cast_count, m.cast_members
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS era
    FROM 
        KeywordedMovies
    WHERE 
        cast_count > 3
)

SELECT 
    era,
    COUNT(*) AS number_of_movies,
    AVG(cast_count) AS average_cast_size,
    STRING_AGG(title, ', ') AS titles
FROM 
    FilteredMovies
GROUP BY 
    era
ORDER BY 
    average_cast_size DESC;
