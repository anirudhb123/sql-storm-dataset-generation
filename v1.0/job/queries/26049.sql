WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL 
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

KeywordStats AS (
    SELECT 
        keyword,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        keyword
    HAVING 
        COUNT(DISTINCT movie_id) > 1
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast_members,
        RANK() OVER (ORDER BY total_cast_members DESC) AS cast_rank
    FROM 
        RankedMovies
    WHERE 
        movie_rank = 1
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast_members,
    ks.keyword,
    ks.movie_count
FROM 
    TopMovies tm
JOIN 
    KeywordStats ks ON tm.movie_id IN (
        SELECT 
            mk.movie_id
        FROM 
            movie_keyword mk
        JOIN 
            keyword kw ON mk.keyword_id = kw.id
        WHERE 
            kw.keyword = ks.keyword
    )
WHERE 
    tm.cast_rank <= 10
ORDER BY 
    tm.total_cast_members DESC, 
    ks.movie_count DESC;