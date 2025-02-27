WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL AND t.production_year IS NOT NULL
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        cast_info AS ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
    HAVING 
        COUNT(ci.id) > 3 AND rm.title_rank <= 5 -- Only consider movies with more than 3 cast members and top 5 titles
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_kind
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL -- Filter out companies with NULL country codes
),
MovieDetails AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        ci.company_name,
        ci.company_kind,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS synopsis,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS budget
    FROM 
        PopularMovies AS pm
    LEFT JOIN 
        CompanyInfo AS ci ON pm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info AS mi ON pm.movie_id = mi.movie_id
    GROUP BY 
        pm.movie_id, pm.title, pm.production_year, ci.company_name, ci.company_kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.company_name, 'Indie') AS production_company,
    COALESCE(md.company_kind, 'Independent') AS company_type,
    md.synopsis,
    md.budget,
    CASE 
        WHEN md.budget IS NULL THEN 'Budget Info Not Available'
        ELSE 'Budget Info Available'
    END AS budget_status,
    row_number() OVER (ORDER BY md.production_year DESC) AS movie_rank_by_year
FROM 
    MovieDetails AS md
ORDER BY 
    md.production_year DESC,
    md.title ASC;
