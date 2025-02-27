WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT m.id) FILTER (WHERE mc.company_type_id = 1) AS production_companies,
        MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS summary_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info i ON t.id = i.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        md.*, 
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, production_year DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.title_id, 
    rm.title, 
    rm.production_year, 
    rm.aka_names, 
    rm.total_cast,
    rm.production_companies,
    rm.summary_info,
    rm.keyword_count,
    COALESCE(rm.total_cast / NULLIF(rm.production_companies, 0), 0) AS cast_to_company_ratio
FROM 
    RankedMovies rm
WHERE 
    rm.production_year IS NOT NULL
    AND rm.total_cast > 0
    AND rm.rank <= 100
ORDER BY 
    rm.rank;
