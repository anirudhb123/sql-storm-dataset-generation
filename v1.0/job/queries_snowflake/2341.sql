
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS year_rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.production_year,
    COUNT(*) AS movie_count,
    MAX(rm.keyword_count) AS max_keywords,
    MIN(rm.keyword_count) AS min_keywords,
    AVG(rm.keyword_count) AS avg_keywords,
    LISTAGG(rm.title, '; ') WITHIN GROUP (ORDER BY rm.title) AS movies_with_max_keywords
FROM 
    RankedMovies rm
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.production_year
HAVING 
    MAX(rm.keyword_count) IS NOT NULL
ORDER BY 
    rm.production_year DESC;
