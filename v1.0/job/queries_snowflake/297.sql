
WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        LISTAGG(CAST(mk.keyword_id AS TEXT), ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(kd.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyCounts cc ON md.movie_title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    KeywordDetails kd ON md.production_year = (SELECT production_year FROM aka_title WHERE id = kd.movie_id)
WHERE 
    md.actor_rank <= 5
GROUP BY 
    md.movie_title, 
    md.production_year, 
    md.actor_name, 
    cc.company_count, 
    kd.keywords
ORDER BY 
    md.production_year DESC, md.actor_name ASC;
