WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actors,
        COUNT(DISTINCT mcc.company_id) AS production_companies,
        COUNT(DISTINCT mk.keyword) AS keywords_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mcc ON t.id = mcc.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
        AND t.production_year <= 2023
    GROUP BY 
        t.title, t.production_year
),
HighKeywordCount AS (
    SELECT 
        title,
        production_year
    FROM 
        MovieDetails
    WHERE 
        keywords_count > 5
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY production_year DESC) AS year_rank
    FROM 
        MovieDetails
)
SELECT 
    r.title,
    r.production_year,
    r.actors,
    CASE 
        WHEN hkc.title IS NOT NULL THEN 'High Keyword Count' 
        ELSE 'Regular' 
    END AS keyword_status
FROM 
    RankedMovies AS r
LEFT JOIN 
    HighKeywordCount AS hkc ON r.title = hkc.title AND r.production_year = hkc.production_year
WHERE 
    year_rank <= 10
ORDER BY 
    r.production_year DESC, r.title;
