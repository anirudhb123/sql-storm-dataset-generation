WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.movie_id,
        a.name AS actor_name,
        COALESCE(cmp.name, 'Unknown Company') AS company_name,
        CASE 
            WHEN cm.kind LIKE '%Distributor%' THEN 'Distributor'
            WHEN cm.kind LIKE '%Producer%' THEN 'Producer'
            ELSE 'Other'
        END AS company_type,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cmp ON mc.company_id = cmp.id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, a.name, cmp.name, cm.kind
)
SELECT 
    md.movie_id,
    md.actor_name,
    md.company_name,
    md.company_type,
    md.keyword_count,
    COUNT(DISTINCT p.id) OVER (PARTITION BY md.movie_id) AS distinct_person_count,
    MAX(md.keyword_count) OVER (PARTITION BY md.company_name ORDER BY md.keyword_count DESC) AS max_keyword_count_per_company
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.company_type, md.keyword_count DESC
FETCH FIRST 100 ROWS ONLY;
