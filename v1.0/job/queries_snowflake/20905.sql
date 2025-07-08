
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        ai.person_id,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    GROUP BY 
        ai.person_id
),
movie_company_types AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT ct.kind, ', ') AS company_kinds
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
detailed_info AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        rc.movie_count,
        mct.company_kinds,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS detailed_rank
    FROM 
        ranked_movies t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        actor_movie_counts rc ON rc.person_id = (SELECT ai.person_id FROM cast_info ci JOIN aka_name ai ON ci.person_id = ai.person_id WHERE ci.movie_id = t.movie_id LIMIT 1)
    LEFT JOIN 
        movie_company_types mct ON t.movie_id = mct.movie_id
    WHERE 
        EXISTS (
            SELECT 1 
            FROM title tt 
            WHERE tt.id = t.movie_id 
            AND tt.kind_id IS NOT NULL
            AND tt.production_year IS NOT NULL
        )
)
SELECT 
    di.title,
    di.production_year,
    di.keyword,
    di.movie_count,
    di.company_kinds
FROM 
    detailed_info di
WHERE 
    di.detailed_rank <= 10
ORDER BY 
    di.production_year DESC,
    di.title ASC
LIMIT 10 OFFSET 5;
