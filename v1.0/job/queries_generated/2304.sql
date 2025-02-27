WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY a.production_year DESC) as YearRank
    FROM 
        aka_title a
    WHERE 
        a.kind_id = 1
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m 
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(kw.keywords, 'No Keywords') AS keywords,
        COALESCE(ci.company_name, 'Independent') AS company_name,
        COALESCE(ci.company_type, 'N/A') AS company_type,
        t.imdb_id
    FROM 
        title t
    LEFT JOIN 
        MovieKeywords kw ON t.id = kw.movie_id
    LEFT JOIN 
        CompanyInfo ci ON t.id = ci.movie_id
    WHERE 
        t.production_year > 2000
)

SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_name,
    md.company_type,
    (SELECT COUNT(*) 
     FROM cast_info c 
     WHERE c.movie_id = md.movie_id) AS total_cast,
    (SELECT AVG(mr.rating) 
     FROM movie_rating mr 
     WHERE mr.movie_id = md.movie_id 
     GROUP BY mr.movie_id) AS avg_rating
FROM 
    MovieDetails md
WHERE 
    md.company_type != 'N/A'
ORDER BY 
    md.production_year DESC,
    md.title ASC;

