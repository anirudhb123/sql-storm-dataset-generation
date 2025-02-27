WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        c.id AS company_id,
        cn.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS company_order,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY a.id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        p.name AS actor_name, 
        c.movie_id,
        COUNT(DISTINCT ci.id) AS roles_played
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        p.name, c.movie_id
),
FinalOutput AS (
    SELECT 
        md.title, 
        md.production_year, 
        md.company_name,
        ad.actor_name,
        ad.roles_played,
        md.keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorDetails ad ON md.movie_id = ad.movie_id
)
SELECT 
    title,
    production_year,
    company_name,
    actor_name,
    roles_played,
    keyword_count
FROM 
    FinalOutput
WHERE 
    roles_played > 1
ORDER BY 
    production_year DESC, 
    keyword_count DESC
LIMIT 100;
