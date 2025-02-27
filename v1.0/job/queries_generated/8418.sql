WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        k.keyword,
        c.role_id,
        a.name AS actor_name,
        p.info AS person_info
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        rm.rank_by_year <= 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT md.person_info, ', ') AS person_infos
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.title;
