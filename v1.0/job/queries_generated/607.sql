WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, c.nr_order) AS rank,
        COUNT(DISTINCT m.company_id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        complete_cast c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rank,
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(NULLIF(f.company_count, 0), 'No companies') AS company_count_info,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = f.movie_id 
       AND ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'actor')
    ) AS actor_count,
    (SELECT STRING_AGG(DISTINCT a.name, ', ') 
     FROM aka_name a 
     JOIN cast_info ci ON a.person_id = ci.person_id 
     WHERE ci.movie_id = f.movie_id
    ) AS actor_names
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC;
