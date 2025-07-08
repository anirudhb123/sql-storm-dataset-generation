
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_order
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        rt.role, 
        COUNT(*) OVER (PARTITION BY ci.person_id, rt.role) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieKeywordInfo AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    at.title AS movie_title,
    at.production_year,
    ak.name AS actor_name,
    ar.role,
    ar.role_count,
    mki.keywords,
    mki.keyword_count,
    COALESCE(ex.year_difference, 0) AS year_difference,
    CASE 
        WHEN ar.role_count > 1 THEN 'Starring'
        ELSE 'Cameo'
    END AS role_category
FROM 
    RankedTitles at
LEFT JOIN 
    cast_info ci ON at.title_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    ActorRoles ar ON ci.person_id = ar.person_id AND ci.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywordInfo mki ON at.title_id = mki.movie_id
CROSS JOIN 
    (
        SELECT 
            EXTRACT(YEAR FROM '2024-10-01'::DATE) - MIN(AT2.production_year) AS year_difference
        FROM 
            aka_title AT2 
        WHERE 
            AT2.production_year IS NOT NULL
    ) ex
WHERE 
    at.rank_order <= 5
ORDER BY 
    at.production_year DESC, ak.name;
