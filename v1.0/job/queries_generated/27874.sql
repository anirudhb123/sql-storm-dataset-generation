WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        ct.kind AS company_type,
        cn.name AS company_name,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON rm.title_id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year, ct.kind, cn.name
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.company_type,
    md.actors,
    COUNT(md.actors) AS actor_count
FROM 
    MovieDetails md
WHERE 
    md.year_rank <= 5
GROUP BY 
    md.title, md.production_year, md.company_name, md.company_type
ORDER BY 
    md.production_year DESC, actor_count DESC;
