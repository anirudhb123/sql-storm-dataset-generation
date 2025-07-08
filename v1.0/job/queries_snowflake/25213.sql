WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    INNER JOIN 
        cast_info ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
),
KeyWordCounts AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title
),
TopKeywords AS (
    SELECT 
        movie_id,
        movie_title,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        KeyWordCounts
),
FinalResults AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        tk.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        TopKeywords tk ON rm.year_rank <= 5 AND rm.movie_title = tk.movie_title 
)

SELECT 
    fr.movie_title,
    fr.production_year,
    fr.actor_name,
    fr.keyword_count
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC
LIMIT 10;