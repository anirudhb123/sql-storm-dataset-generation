WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
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
),
MovieDetails AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count,
        cm.company_name,
        cm.company_type,
        km.keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyMovies cm ON r.id = cm.movie_id
    LEFT JOIN 
        KeywordMovies km ON r.id = km.movie_id
    WHERE 
        r.rank <= 5
)
SELECT 
    title,
    production_year,
    CAST(coalesce(cast_count, 0) AS INTEGER) AS cast_count,
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type,
    COALESCE(keywords, 'No keywords') AS keywords
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, cast_count DESC;
