WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
MoviesWithDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast,
        ak.name AS main_actor,
        ak.imdb_index AS actor_index,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.total_cast DESC, ak.name) AS actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.title = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CastDetails AS (
    SELECT 
        m.title,
        m.production_year,
        STRING_AGG(ak.name, ', ') AS cast_names,
        COUNT(ci.id) AS cast_count,
        COALESCE(SUM(CASE WHEN ak.name IS NULL THEN 1 ELSE 0 END), 0) AS null_actors
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    ci.company_name,
    ci.company_type,
    md.null_actors,
    CASE 
        WHEN md.cast_count > 5 THEN 'Large Ensemble' 
        WHEN md.cast_count BETWEEN 3 AND 5 THEN 'Medium Ensemble' 
        ELSE 'Small Ensemble' 
    END AS ensemble_size,
    COUNT(DISTINCT cp.id) AS unique_companies
FROM 
    CastDetails md
LEFT JOIN 
    CompanyInfo ci ON md.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
LEFT JOIN 
    movie_companies mc ON md.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
LEFT JOIN 
    company_name cp ON mc.company_id = cp.id
WHERE 
    md.null_actors < 2 -- Filter for movies with very few null actors
GROUP BY 
    md.title, md.production_year, ci.company_name, ci.company_type, md.null_actors
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
