WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        actor_count_rank <= 10
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(mc.company_names, 'None') AS company_names,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = tm.movie_id) AS keyword_count,
    (SELECT AVG(pi.info::numeric) 
     FROM person_info pi
     JOIN cast_info ci ON pi.person_id = ci.person_id
     WHERE ci.movie_id = tm.movie_id AND pi.info_type_id = 1
    ) AS average_person_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
