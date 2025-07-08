
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        at.kind_id,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    LEFT JOIN 
        aka_name ak ON ak.id = at.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year, at.kind_id
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        LISTAGG(CONCAT(cn.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY cn.name) AS cast_details
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON rt.id = ci.role_id
    JOIN 
        name cn ON cn.id = ci.person_id
    WHERE 
        rt.role IS NOT NULL
    GROUP BY 
        ci.movie_id
),
FinalOutput AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        tt.aka_names,
        fc.cast_details,
        kt.keyword AS keywords,
        tt.kind_id
    FROM 
        RankedTitles tt
    LEFT JOIN 
        FilteredCast fc ON tt.title_id = fc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tt.title_id
    LEFT JOIN 
        keyword kt ON kt.id = mk.keyword_id
    WHERE 
        tt.title_rank <= 5  
)

SELECT 
    fo.title,
    fo.production_year,
    fo.aka_names,
    fo.cast_details,
    LISTAGG(DISTINCT fo.keywords, ', ') WITHIN GROUP (ORDER BY fo.keywords) AS keywords
FROM 
    FinalOutput fo
GROUP BY 
    fo.title, fo.production_year, fo.aka_names, fo.cast_details
ORDER BY 
    fo.production_year DESC, fo.title;
