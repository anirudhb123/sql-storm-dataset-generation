
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS genre_names
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON c.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        m.production_year >= 2000
        AND k.keyword ILIKE '%Drama%'
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    CONCAT('Rank: ', tm.rank) AS movie_rank,
    ROUND(AVG(p.info_length), 2) AS avg_person_info_length
FROM 
    TopMovies tm
LEFT JOIN (
    SELECT 
        ci.person_id,
        AVG(LENGTH(pi.info)) AS info_length
    FROM 
        person_info pi
    JOIN 
        cast_info ci ON pi.person_id = ci.person_id
    GROUP BY 
        ci.person_id
) p ON p.person_id IN (
    SELECT 
        c.person_id 
    FROM 
        cast_info c 
    WHERE 
        c.movie_id = tm.movie_id
)
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.rank
ORDER BY 
    tm.rank;
