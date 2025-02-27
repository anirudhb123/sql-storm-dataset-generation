WITH MovieRank AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_member_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT p.info, '; ') AS person_info
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_member_count,
        RANK() OVER (ORDER BY cast_member_count DESC) AS rank
    FROM 
        MovieRank
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_member_count,
    tm.keywords,
    tm.person_info
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
