
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
GenreRank AS (
    SELECT 
        k.keyword AS genre,
        m.movie_id,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY COUNT(*) DESC) AS genre_rank
    FROM 
        RankedMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        k.keyword, m.movie_id
), 
TopGenres AS (
    SELECT 
        g.movie_id,
        LISTAGG(g.genre, ', ') AS genres
    FROM 
        GenreRank g
    WHERE 
        g.genre_rank <= 3  
    GROUP BY 
        g.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.keyword_count,
    tg.genres
FROM 
    RankedMovies rm
LEFT JOIN 
    TopGenres tg ON rm.movie_id = tg.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC, 
    rm.keyword_count DESC;
