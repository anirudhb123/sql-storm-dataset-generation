
WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.kind_id,
    cs.total_cast,
    cs.cast_names,
    ks.keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_summary cs ON rt.title_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON rt.title_id = ks.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.kind_id, rt.production_year DESC;
