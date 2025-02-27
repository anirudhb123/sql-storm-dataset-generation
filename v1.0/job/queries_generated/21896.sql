WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        r.title, 
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.movie_rank <= 5
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS total_movies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        m.movie_id, c.name, ct.kind
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cm.company_name,
    cm.company_type,
    CASE 
        WHEN km.keywords IS NOT NULL THEN km.keywords 
        ELSE 'No Keywords Available' 
    END AS keywords,
    COALESCE(cm.total_movies, 0) AS total_movies_by_company,
    CASE 
        WHEN cm.total_movies > 10 THEN 'Active' 
        ELSE 'Less Active' 
    END AS company_activity_status
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovies cm ON tm.title = (SELECT m.title FROM aka_title m WHERE m.id = cm.movie_id)
LEFT JOIN 
    KeywordMovies km ON tm.title = (SELECT m.title FROM aka_title m WHERE m.id = km.movie_id)
WHERE 
    NOT EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = tm.id AND mi.info_type_id IS NULL)
ORDER BY 
    tm.production_year DESC, 
    CAST(total_movies_by_company AS INTEGER) DESC;
