
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ak.name AS actor_name,
        ak.name_pcode_cf AS actor_pcode,
        p.gender AS actor_gender,
        k.keyword AS movie_keyword,
        mi.info AS movie_info,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_order
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS c ON mc.company_type_id = c.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        name AS p ON ak.person_id = p.imdb_id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info AS mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
        AND c.kind LIKE '%Studio%'
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_gender,
    actor_order,
    LISTAGG(movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords,
    LISTAGG(DISTINCT movie_info, '; ') WITHIN GROUP (ORDER BY movie_info) AS additional_info
FROM 
    movie_details
GROUP BY 
    movie_title, production_year, actor_name, actor_gender, actor_order
ORDER BY 
    production_year DESC, movie_title, actor_order;
