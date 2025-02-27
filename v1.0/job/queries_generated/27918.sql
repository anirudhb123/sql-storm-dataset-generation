WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_size
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count 
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mci.company_id,
        cn.name AS company_name,
        cl.role AS actor_role
    FROM 
        TopMovies tm
    JOIN 
        movie_companies mci ON tm.movie_id = mci.movie_id
    JOIN 
        company_name cn ON mci.company_id = cn.id
    JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type cl ON ci.role_id = cl.id
)
SELECT 
    md.title,
    md.production_year,
    COUNT(DISTINCT md.company_name) AS total_companies,
    STRING_AGG(DISTINCT md.actor_role, ', ') AS all_actor_roles
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year
ORDER BY 
    md.production_year DESC, total_companies DESC;
