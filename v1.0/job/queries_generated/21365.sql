WITH MovieRankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(CAST.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(CAST.id) DESC) AS rank_within_year
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS CAST ON t.id = CAST.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        MovieRankings
    WHERE 
        rank_within_year <= 5
),
DirectorCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies AS mc
    INNER JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        mc.movie_id
),
KeywordList AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    INNER JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        dc.company_count,
        kl.keywords
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        DirectorCount AS dc ON tm.movie_id = dc.movie_id
    LEFT JOIN 
        KeywordList AS kl ON tm.movie_id = kl.movie_id
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.company_count, 0) AS director_count,
    COALESCE(f.keywords, 'No keywords') AS keywords
FROM 
    FilteredMovies AS f
WHERE 
    f.production_year IS NOT NULL
ORDER BY 
    f.production_year DESC, f.director_count DESC;
