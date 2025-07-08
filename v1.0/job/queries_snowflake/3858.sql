
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_exists
    FROM 
        title t
    LEFT JOIN 
        aka_title ak_t ON t.id = ak_t.movie_id
    LEFT JOIN 
        aka_name ak ON ak_t.id = ak.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
RankedMovies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC) AS rank_by_company
    FROM 
        MovieDetails md
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actors,
    rm.company_count,
    rm.rank_by_company,
    COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.title_id), 0) AS keyword_count
FROM 
    RankedMovies rm
WHERE 
    rm.production_year IS NOT NULL AND 
    rm.rank_by_company <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC;
