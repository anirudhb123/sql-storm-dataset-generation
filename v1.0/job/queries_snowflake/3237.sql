
WITH movie_ranks AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(*) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
cast_movie_info AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cm.name AS company_name,
        COALESCE(ct.kind, 'Unknown') AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    cm.total_cast,
    cm.cast_names,
    ci.company_name,
    ci.company_type
FROM 
    movie_ranks mr
LEFT JOIN 
    cast_movie_info cm ON mr.movie_id = cm.movie_id
LEFT JOIN 
    company_info ci ON mr.movie_id = ci.movie_id
WHERE 
    mr.rank <= 5
ORDER BY 
    mr.production_year DESC, 
    mr.rank;
