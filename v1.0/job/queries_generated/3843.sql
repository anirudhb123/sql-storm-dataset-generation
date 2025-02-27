WITH movie_details AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        COALESCE(cast_info.nr_order, 0) AS cast_order,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ON a.id = cast_info.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.id, cast_info.nr_order
),
ranked_movies AS (
    SELECT 
        title,
        production_year,
        kind_id,
        cast_order,
        keyword_count,
        company_count,
        RANK() OVER (PARTITION BY kind_id ORDER BY keyword_count DESC, company_count DESC) AS rank_within_kind
    FROM 
        movie_details
)
SELECT 
    rm.title,
    rm.production_year,
    k.kind AS kind_name,
    rm.cast_order,
    rm.keyword_count,
    rm.company_count
FROM 
    ranked_movies rm
JOIN 
    kind_type k ON rm.kind_id = k.id
WHERE 
    rm.rank_within_kind <= 10
ORDER BY 
    k.kind, rm.rank_within_kind;
