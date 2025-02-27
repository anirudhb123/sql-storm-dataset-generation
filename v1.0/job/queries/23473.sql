WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_count_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        role_count_rank <= 3
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.movie_id) AS cast_members_count
    FROM 
        TopRankedMovies t
    LEFT JOIN 
        MovieKeywordCounts mkc ON t.movie_id = mkc.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.cast_members_count,
    CASE 
        WHEN fr.keyword_count > fr.cast_members_count THEN 'More Keywords than Cast Members'
        WHEN fr.keyword_count < fr.cast_members_count THEN 'More Cast Members than Keywords'
        ELSE 'Equal Keywords and Cast Members'
    END AS comparison_result
FROM 
    FinalResults fr
WHERE 
    fr.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    fr.production_year DESC,
    fr.keyword_count DESC;