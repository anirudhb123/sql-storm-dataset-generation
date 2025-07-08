WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COALESCE(b.name, 'Unknown') AS company_name,
        COUNT(c.person_id) AS total_cast,
        SUM(CASE WHEN d.kind IS NOT NULL THEN 1 ELSE 0 END) AS has_comp_cast
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name b ON mc.company_id = b.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        comp_cast_type d ON c.person_role_id = d.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year, b.name
),
FilteredRankedMovies AS (
    SELECT 
        *,
        CASE 
            WHEN total_cast > 5 THEN 'Large Cast'
            WHEN total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    *,
    CASE 
        WHEN has_comp_cast > 0 THEN 'Collaborative'
        ELSE 'Solo'
    END AS collaboration_status
FROM 
    FilteredRankedMovies
ORDER BY 
    production_year DESC, total_cast DESC;

