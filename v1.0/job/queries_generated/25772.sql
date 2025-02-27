WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS cast_type,
        ak.name AS actor_name,
        ak.name_pcode_nf AS actor_name_pcode_nf,
        ak.name_pcode_cf AS actor_name_pcode_cf,
        pi.info AS actor_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000 AND t.production_year <= 2023
),

KeywordDetails AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS movie_keyword,
        k.phonetic_code
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),

Summary AS (
    SELECT 
        md.movie_title,
        md.production_year,
        ARRAY_AGG(DISTINCT md.actor_name) AS actors,
        ARRAY_AGG(DISTINCT md.actor_name_pcode_nf) AS actor_name_pcode_nf,
        ARRAY_AGG(DISTINCT md.actor_name_pcode_cf) AS actor_name_pcode_cf,
        ARRAY_AGG(DISTINCT md.actor_info) AS actor_info_list,
        ARRAY_AGG(DISTINCT kd.movie_keyword) AS movie_keywords,
        COUNT(DISTINCT md.actor_name) AS actor_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_title = kd.movie_title
    GROUP BY 
        md.movie_title, md.production_year
)

SELECT 
    movie_title,
    production_year,
    actor_count,
    actors,
    actor_info_list,
    movie_keywords
FROM 
    Summary
ORDER BY 
    production_year DESC, actor_count DESC;
