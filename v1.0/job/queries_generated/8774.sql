WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title ASC) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        c.person_id,
        p.name AS actor_name,
        ct.kind AS company_type,
        ki.keyword AS movie_keyword
    FROM
        RankedMovies rm
    JOIN complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN cast_info ci ON cc.id = ci.id
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN movie_companies mc ON rm.movie_id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    WHERE
        rm.title_rank = 1
)
SELECT 
    d.movie_id,
    d.title,
    d.production_year,
    d.actor_name,
    COUNT(DISTINCT d.movie_keyword) AS keyword_count,
    STRING_AGG(DISTINCT d.company_type, ', ') AS company_types
FROM 
    MovieDetails d
GROUP BY 
    d.movie_id, d.title, d.production_year, d.actor_name
ORDER BY 
    d.production_year DESC, d.title ASC;
