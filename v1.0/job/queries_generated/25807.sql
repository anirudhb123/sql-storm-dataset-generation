WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS keyword,
        COALESCE(COUNT(DISTINCT c.person_id), 0) AS num_cast_members,
        COALESCE(STRING_AGG(DISTINCT a.name, ', '), 'No Cast') AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
), 
KeywordCounts AS (
    SELECT 
        keyword,
        COUNT(movie_id) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        keyword
    HAVING 
        COUNT(movie_id) > 1
),
TopKeywords AS (
    SELECT 
        keyword
    FROM 
        KeywordCounts
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.num_cast_members,
    rm.cast_names
FROM 
    RankedMovies rm
JOIN 
    TopKeywords tk ON rm.keyword = tk.keyword
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast_members DESC;
