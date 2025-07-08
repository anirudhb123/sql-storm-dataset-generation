WITH MovieStats AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_per_cast,
        MAX(CASE WHEN at.production_year IS NOT NULL THEN at.production_year ELSE 0 END) AS latest_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.total_cast,
        ms.avg_roles_per_cast,
        ms.latest_year,
        RANK() OVER (ORDER BY ms.total_cast DESC) AS cast_rank
    FROM 
        MovieStats ms
)
SELECT 
    tm.title,
    tm.total_cast,
    tm.avg_roles_per_cast,
    CASE 
        WHEN tm.latest_year < 2000 THEN 'Classic'
        WHEN tm.latest_year >= 2000 AND tm.latest_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    TopMovies tm
WHERE 
    tm.cast_rank <= 10
ORDER BY 
    tm.total_cast DESC;