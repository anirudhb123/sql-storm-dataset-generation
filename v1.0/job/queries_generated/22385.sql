WITH ranked_movies AS (
    SELECT 
        at.title AS movie_title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY at.id) AS num_companies
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
extended_cast AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        ci.note AS role_note,
        CASE 
            WHEN ci.note IS NULL THEN 'Unspecified Role' 
            ELSE ci.note 
        END AS resolved_role,
        (SELECT COUNT(*) FROM cast_info ci2 WHERE ci2.movie_id = ci.movie_id) AS total_cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movies_with_keywords AS (
    SELECT 
        at.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
)
SELECT 
    em.movie_title, 
    em.production_year, 
    em.rank_per_year,
    em.num_companies,
    ec.actor_name,
    ec.resolved_role,
    mwk.keywords_list 
FROM 
    ranked_movies em
LEFT JOIN 
    extended_cast ec ON em.movie_id = ec.movie_id
LEFT JOIN 
    movies_with_keywords mwk ON em.movie_title = mwk.movie_title
WHERE 
    (em.rank_per_year <= 5 OR ec.total_cast_count > 10)
    AND (mwk.keywords_list IS NOT NULL)
ORDER BY 
    em.production_year DESC, 
    em.rank_per_year ASC;
