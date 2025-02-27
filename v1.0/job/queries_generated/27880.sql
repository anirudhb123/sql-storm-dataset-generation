WITH movie_title_info AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        kt.kind AS movie_kind,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        kind_type kt ON mt.kind_id = kt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year, kt.kind
),
actor_info AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ak.id, ak.name, ak.imdb_index
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mti.movie_title,
    mti.production_year,
    mti.movie_kind,
    mti.keywords,
    ai.actor_name,
    ai.actor_imdb_index,
    ai.roles,
    ai.movie_count,
    ci.company_names,
    ci.company_types
FROM 
    movie_title_info mti
JOIN 
    cast_info ci ON ci.movie_id = mti.movie_id
JOIN 
    actor_info ai ON ci.person_id = ai.actor_id
LEFT JOIN 
    company_info ci ON ci.movie_id = mti.movie_id
WHERE 
    mti.production_year >= 2000
ORDER BY 
    mti.production_year DESC,
    mti.movie_title;
