WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        r.title, 
        r.production_year, 
        r.cast_count, 
        ci.company_name,
        ci.company_type,
        r.rank_within_year
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyInfo ci ON r.title = ci.movie_id
    WHERE 
        r.rank_within_year <= 3 OR ci.company_rank IS NULL
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(md.company_name, 'No Company') AS company_name,
    COALESCE(md.company_type, 'Unknown Type') AS company_type,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = md.title) AS keyword_count
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
