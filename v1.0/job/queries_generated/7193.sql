WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), genre_count AS (
    SELECT 
        t.id AS title_id,
        COUNT(DISTINCT genre.kind) AS genre_count
    FROM 
        title t
    JOIN 
        kind_type genre ON t.kind_id = genre.id
    GROUP BY 
        t.id
), cast_info_agg AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_member_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
), title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        cc.cast_member_count,
        cc.cast_member_names,
        rc.genre_count
    FROM 
        title t
    LEFT JOIN 
        cast_info_agg cc ON t.id = cc.movie_id
    LEFT JOIN 
        genre_count rc ON t.id = rc.title_id
)
SELECT 
    ti.title_id,
    ti.title,
    ti.production_year,
    ti.cast_member_count,
    ti.cast_member_names,
    rt.keyword AS associated_keyword
FROM 
    title_info ti
LEFT JOIN 
    ranked_titles rt ON ti.title_id = rt.title_id
WHERE 
    ti.cast_member_count > 5 AND ti.production_year > 2000
ORDER BY 
    ti.production_year DESC, ti.title;
