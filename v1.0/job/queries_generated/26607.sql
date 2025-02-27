WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT kg.keyword) AS keywords
    FROM 
        aka_title AS t
    JOIN 
        title AS tt ON t.title = tt.title 
    JOIN 
        movie_info AS mi ON t.movie_id = mi.movie_id 
    JOIN 
        kind_type AS kt ON tt.kind_id = kt.id 
    LEFT JOIN 
        cast_info AS cc ON t.movie_id = cc.movie_id 
    LEFT JOIN 
        aka_name AS ak ON cc.person_id = ak.person_id 
    LEFT JOIN 
        movie_companies AS mc ON t.movie_id = mc.movie_id 
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id 
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id 
    LEFT JOIN 
        keyword AS kg ON mk.keyword_id = kg.id 
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
average_cast AS (
    SELECT 
        AVG(cast_count) AS avg_cast_size 
    FROM 
        movie_details
),
distinct_keywords AS (
    SELECT 
        DISTINCT keyword 
    FROM 
        movie_details, 
        json_each_text(keywords) AS kw
),
keyword_count AS (
    SELECT 
        COUNT(DISTINCT keyword) AS total_keywords 
    FROM 
        distinct_keywords
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_kind,
    md.aliases,
    md.cast_count,
    md.companies,
    md.keywords,
    ac.avg_cast_size,
    k.total_keywords
FROM 
    movie_details AS md
CROSS JOIN 
    average_cast AS ac
CROSS JOIN 
    keyword_count AS k
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;

This SQL query benchmarks string processing by generating a comprehensive report on movies, including their details, cast information, production year, types, associated companies, and keywords. The subqueries calculate averages and distinct counts to provide additional insights into the dataset.
