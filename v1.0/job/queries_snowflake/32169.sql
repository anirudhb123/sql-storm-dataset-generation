
WITH RECURSIVE year_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        MAX(ki.kind) AS movie_kind
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title kt ON ci.movie_id = kt.movie_id
    JOIN 
        kind_type ki ON kt.kind_id = ki.id
    GROUP BY 
        ci.movie_id
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        COALESCE(mi.info, 'No additional info') AS additional_info,
        tt.kind AS title_kind
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        kind_type tt ON t.kind_id = tt.id
)
SELECT 
    ym.movie_title,
    ym.production_year,
    ca.total_actors,
    ca.actor_names,
    ti.additional_info,
    ti.title_kind,
    CASE 
        WHEN ca.total_actors > 5 THEN 'Ensemble Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_category
FROM 
    year_movies ym
LEFT JOIN 
    cast_aggregates ca ON ym.movie_id = ca.movie_id
LEFT JOIN 
    title_info ti ON ym.movie_id = ti.title_id
WHERE 
    ym.year_rank <= 5
    AND (ti.title_kind IS NOT NULL OR ti.additional_info != 'No additional info')
ORDER BY 
    ym.production_year DESC, 
    ca.total_actors DESC;
