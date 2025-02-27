WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
RecentMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),
MovieWithMaxKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.keyword_count,
        ROW_NUMBER() OVER (ORDER BY mwk.keyword_count DESC) AS movie_rank
    FROM 
        MovieWithMaxKeywords mwk
)
SELECT 
    r.title,
    r.production_year,
    CASE 
        WHEN m.keyword_count IS NULL THEN 'No Keywords'
        ELSE CAST(m.keyword_count AS TEXT)
    END AS keyword_info,
    COALESCE(CAST(SUBSTRING(r.title FROM '^(.*)') AS text), 'Untitled') AS refined_title,
    cl.kind AS cast_type,
    COUNT(c.movie_id) AS cast_count
FROM 
    RecentMovies r
LEFT JOIN 
    TopMovies m ON r.title_id = m.movie_id
LEFT JOIN 
    cast_info c ON r.title_id = c.movie_id
LEFT JOIN 
    comp_cast_type cl ON c.role_id = cl.id
WHERE 
    r.production_year >= 2000
GROUP BY 
    r.title, r.production_year, m.keyword_count, cl.kind
HAVING 
    (COUNT(c.movie_id) > 0 OR m.keyword_count IS NOT NULL)
ORDER BY 
    r.production_year DESC, r.title;
