
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FullMovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.company_count,
        cs.company_names,
        pk.keyword_count,
        pk.keywords,
        COALESCE(rm.rank_per_year, 0) AS rank_per_year
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
)
SELECT 
    fmd.movie_id,
    fmd.title,
    fmd.production_year,
    fmd.company_count,
    fmd.company_names,
    fmd.keyword_count,
    fmd.keywords,
    CASE 
        WHEN fmd.rank_per_year = 1 THEN 'Most Popular'
        WHEN fmd.rank_per_year > 0 THEN 'Ranked'
        ELSE 'Unranked' 
    END AS popularity_status
FROM 
    FullMovieDetails fmd
WHERE 
    fmd.production_year >= 2000 
    AND fmd.company_count IS NOT NULL
ORDER BY 
    fmd.production_year DESC, 
    fmd.rank_per_year,
    fmd.title ASC
LIMIT 100;
