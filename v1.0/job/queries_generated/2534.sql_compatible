
WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieTitles AS (
    SELECT 
        a.movie_id, 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year
    FROM 
        MovieTitles mt
    WHERE 
        mt.title_rank <= 5
),
DirectorCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        mc.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    COALESCE(mr.actor_count, 0) AS total_actors,
    dc.company_names
FROM 
    TopMovies mt
LEFT JOIN 
    MovieRoles mr ON mt.movie_id = mr.movie_id
LEFT JOIN 
    DirectorCompanies dc ON mt.movie_id = dc.movie_id
WHERE 
    mt.production_year >= 2000 
    AND (dc.company_names IS NOT NULL OR COALESCE(mr.actor_count, 0) > 5)
ORDER BY 
    mt.production_year DESC, 
    mt.title;
