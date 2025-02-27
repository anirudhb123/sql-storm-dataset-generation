
WITH MovieData AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        pc.kind AS production_company,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_role_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type pc ON mc.company_type_id = pc.id
    LEFT JOIN 
        movie_keyword mw ON mt.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name, pc.kind
),
FilterYear AS (
    SELECT * 
    FROM MovieData 
    WHERE production_year >= 2000
)
SELECT 
    mv.movie_id,
    mv.movie_title,
    mv.production_year,
    mv.actor_name,
    mv.production_company,
    mv.keywords,
    mv.cast_count
FROM 
    FilterYear mv
WHERE 
    mv.keywords IS NOT NULL 
    AND mv.cast_count > 5
ORDER BY 
    mv.production_year DESC, 
    mv.movie_title;
