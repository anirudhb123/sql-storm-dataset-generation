WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanyInfo AS (
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
CastAndRoles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id, ci.role_id
),
FeaturedCast AS (
    SELECT 
        ak.name,
        ak.person_id,
        ci.movie_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.person_id) DESC) AS cast_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id, ci.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mci.company_name, 'Unknown Company') AS company_name,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        COALESCE(fc.cast_rank, 0) AS cast_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        KeywordCount kc ON rm.movie_id = kc.movie_id
    LEFT JOIN 
        FeaturedCast fc ON rm.movie_id = fc.movie_id AND fc.cast_rank <= 3
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.keyword_count,
    AVG(cd.total_cast) AS average_cast,
    SUM(CASE WHEN md.cast_rank IS NOT NULL THEN 1 ELSE 0 END) AS featured_cast_count,
    CASE 
        WHEN md.keyword_count > 5 THEN 'Highly Tagged' 
        WHEN md.keyword_count BETWEEN 1 AND 5 THEN 'Moderately Tagged' 
        ELSE 'Not Tagged' 
    END AS tagging_status,
    (SELECT COUNT(*) FROM title WHERE title.production_year = md.production_year) AS movies_in_same_year
FROM 
    MovieDetails md
LEFT JOIN 
    CastAndRoles cd ON md.movie_id = cd.movie_id
GROUP BY 
    md.title, md.production_year, md.company_name, md.keyword_count
ORDER BY 
    md.production_year DESC, md.keyword_count DESC, md.title;
