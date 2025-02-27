WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT cni.name, ', ') AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cni ON mc.company_id = cni.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
actor_details AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    ad.actor_names,
    ad.actor_count,
    md.keywords,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    movie_details md
LEFT JOIN 
    actor_details ad ON md.movie_id = ad.movie_id
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title ASC;
