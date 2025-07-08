WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
),
TopRatedActors AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(c.movie_id) > 5 
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT cct.kind) AS company_types
    FROM 
        RankedMovies m
    JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    JOIN 
        TopRatedActors a ON cc.subject_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cct ON mc.company_type_id = cct.id
    WHERE 
        m.rn = 1 
    GROUP BY 
        m.movie_id, m.title, m.production_year, a.name
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.company_types,
    k.keyword
FROM 
    MovieDetails md
JOIN 
    RankedMovies rk ON md.movie_id = rk.movie_id
JOIN 
    keyword k ON rk.keyword = k.keyword
ORDER BY 
    md.production_year DESC, md.title;