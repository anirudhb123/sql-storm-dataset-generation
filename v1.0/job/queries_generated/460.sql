WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movies_with_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.total_actors,
        ci.company_name,
        ci.company_type
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_count ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        company_info ci ON rm.movie_id = ci.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.total_actors, 0) AS actor_count,
    STRING_AGG(DISTINCT mw.company_name, ', ') AS companies,
    COUNT(*) FILTER(WHERE mw.production_year = 2023) OVER () AS movies_from_2023,
    CASE 
        WHEN mw.production_year IS NULL THEN 'Unknown Year'
        ELSE TO_CHAR(mw.production_year, 'FM9999')
    END AS formatted_year
FROM 
    movies_with_info mw
WHERE 
    mw.company_name IS NOT NULL
GROUP BY 
    mw.movie_id, mw.title, mw.production_year, mw.total_actors
ORDER BY 
    mw.production_year DESC, actor_count DESC;
