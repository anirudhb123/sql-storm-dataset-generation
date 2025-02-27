WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywordCount AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(keyword_id) AS keyword_count
        FROM 
            movie_keyword 
        GROUP BY 
            movie_id) mk_count 
    ON tm.title_id = mk_count.movie_id
    LEFT JOIN 
        MovieKeywords mk 
    ON tm.title_id = mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.keyword_count,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    CASE 
        WHEN ak.name IS NULL THEN 'No actor associated'
        ELSE (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = m.title_id)
    END AS associated_actors_count,
    NULLIF(m.keyword_count, 0) AS non_zero_keyword_count,
    CASE 
        WHEN m.production_year IS NOT NULL AND m.production_year < 2000 THEN 'Classic Movie'
        WHEN m.production_year IS NOT NULL AND m.production_year >= 2000 AND m.production_year < 2010 THEN 'Modern Classic'
        ELSE 'Recent Release'
    END AS movie_age_category
FROM 
    MoviesWithKeywordCount m
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = m.title_id)
ORDER BY 
    m.production_year DESC, 
    m.keyword_count DESC 
FETCH FIRST 10 ROWS ONLY;
