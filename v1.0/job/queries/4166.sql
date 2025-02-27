WITH MovieDetails AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COALESCE(SUM(mk.id), 0) AS keyword_count,
        COUNT(DISTINCT cc.subject_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON at.movie_id = cc.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.keyword_count,
        md.actor_count,
        CASE 
            WHEN md.actor_count > 10 THEN 'Blockbuster'
            WHEN md.actor_count BETWEEN 5 AND 10 THEN 'Popular'
            ELSE 'Indie'
        END AS classification
    FROM 
        MovieDetails md
    WHERE 
        md.rn = 1
        AND md.production_year > 2000
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.keyword_count,
    f.actor_count,
    f.classification,
    COALESCE(cn.name, 'Unknown') AS company_name
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_companies mc ON f.title_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    (f.actor_count > 0 OR f.keyword_count > 0)
ORDER BY 
    f.production_year DESC, 
    f.title;
