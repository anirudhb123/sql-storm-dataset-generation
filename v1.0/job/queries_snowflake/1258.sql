WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY k.keyword) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
company_stats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        SUM(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS distributor_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name
)
SELECT 
    rm.title,
    rm.production_year,
    cs.company_name,
    cs.num_companies,
    cs.distributor_count,
    MIN(NULLIF(CASE 
        WHEN cs.distributor_count > 0 THEN 'Has Distributor' 
        ELSE 'No Distributor' 
    END, 'No Distributor')) OVER (PARTITION BY rm.production_year) AS distributor_status
FROM 
    ranked_movies rm
LEFT JOIN 
    company_stats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year, rm.title;
