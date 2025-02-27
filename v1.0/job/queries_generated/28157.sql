WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank
    FROM 
        title m
    WHERE 
        m.production_year >= 2000
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT c.role_id ORDER BY c.nr_order) AS roles,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN cast_info c ON tm.movie_id = c.movie_id
    LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
PersonInfo AS (
    SELECT 
        ak.name AS actor_name,
        pi.info AS actor_info,
        pi.person_id
    FROM 
        aka_name ak
    JOIN person_info pi ON ak.person_id = pi.person_id
)
SELECT 
    md.title,
    md.production_year,
    md.roles,
    md.company_names,
    pi.actor_name, 
    pi.actor_info
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    PersonInfo pi ON ci.person_id = pi.person_id
WHERE 
    md.production_year BETWEEN 2010 AND 2020
ORDER BY 
    md.production_year DESC, md.title;
