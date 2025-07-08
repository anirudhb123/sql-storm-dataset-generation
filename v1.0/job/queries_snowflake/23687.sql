
WITH 
    ranked_movies AS (
        SELECT 
            t.id AS movie_id, 
            t.title, 
            t.production_year, 
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_by_year
        FROM 
            aka_title t
        WHERE 
            t.production_year IS NOT NULL
    ),
    movie_with_actors AS (
        SELECT 
            rm.movie_id, 
            rm.title, 
            COUNT(ci.person_id) AS actor_count,
            LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
        FROM 
            ranked_movies rm
        LEFT JOIN 
            cast_info ci ON rm.movie_id = ci.movie_id
        LEFT JOIN 
            aka_name ak ON ci.person_id = ak.person_id
        GROUP BY 
            rm.movie_id, rm.title
    ),
    movies_with_keywords AS (
        SELECT 
            mw.movie_id, 
            mw.title, 
            mw.actor_count, 
            mw.actor_names,
            COALESCE(LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword), 'No Keywords') AS keywords_list
        FROM 
            movie_with_actors mw
        LEFT JOIN 
            movie_keyword mk ON mw.movie_id = mk.movie_id
        LEFT JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mw.movie_id, mw.title, mw.actor_count, mw.actor_names
    ),
    company_movies AS (
        SELECT 
            mc.movie_id,
            c.name AS company_name,
            ct.kind AS company_type,
            COALESCE(ct.kind, 'Unknown') AS co_type_handled
        FROM 
            movie_companies mc
        LEFT JOIN 
            company_name c ON mc.company_id = c.id
        LEFT JOIN 
            company_type ct ON mc.company_type_id = ct.id
        GROUP BY 
            mc.movie_id, c.name, ct.kind
    ),
    movies_details AS (
        SELECT 
            mw.movie_id,
            mw.title,
            mw.actor_count,
            mw.actor_names,
            mw.keywords_list,
            LISTAGG(DISTINCT co.company_name || ' (' || co.co_type_handled || ')', ', ') WITHIN GROUP (ORDER BY co.company_name) AS companies_involved
        FROM 
            movies_with_keywords mw
        LEFT JOIN 
            company_movies co ON mw.movie_id = co.movie_id
        GROUP BY 
            mw.movie_id, mw.title, mw.actor_count, mw.actor_names, mw.keywords_list
    )
SELECT 
    md.movie_id,
    md.title,
    md.actor_count,
    md.actor_names,
    md.keywords_list,
    md.companies_involved,
    CASE 
        WHEN md.actor_count > 10 AND md.keywords_list LIKE '%Action%'
        THEN 'Blockbuster'
        WHEN md.actor_count < 3
        THEN 'Low Budget'
        ELSE 'Average'
    END AS movie_category,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = md.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Critics Review')) AS review_count
FROM 
    movies_details md
WHERE 
    md.actor_count > 0
ORDER BY 
    md.actor_count DESC, md.title ASC
LIMIT 100;
