WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT mci.company_id) 
     FROM movie_companies mci 
     WHERE mci.movie_id = m.movie_id) AS company_count,
    CASE 
        WHEN m.movie_rank <= 3 THEN 'Top 3 in Year'
        ELSE 'Other'
    END AS ranking_category
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year, m.movie_rank;
