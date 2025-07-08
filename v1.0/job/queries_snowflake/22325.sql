
WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        at.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
actor_movie_info AS (
    SELECT 
        an.name AS actor_name,
        at.title AS movie_title,
        COALESCE(ct.kind, 'Unknown') AS role_type,
        COUNT(ci.id) AS role_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
    GROUP BY 
        an.name, at.title, ct.kind
),
movie_keywords AS (
    SELECT 
        at.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
),
movie_company_info AS (
    SELECT 
        at.title,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mo.id) AS movie_count
    FROM 
        movie_companies mo
    JOIN 
        aka_title at ON mo.movie_id = at.movie_id
    JOIN 
        company_name cn ON mo.company_id = cn.id
    JOIN 
        company_type ct ON mo.company_type_id = ct.id
    GROUP BY 
        at.title, cn.name, ct.kind
)
SELECT 
    am.actor_name,
    am.movie_title,
    COALESCE(rm.production_year, (SELECT MAX(production_year) FROM ranked_movies)) AS production_year,
    am.role_type,
    am.role_count,
    am.notes_present,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mci.company_name, 'No company') AS company_name,
    mci.company_type,
    mci.movie_count
FROM 
    actor_movie_info am
LEFT JOIN 
    ranked_movies rm ON am.movie_title = rm.title AND rm.rank = 1
LEFT JOIN 
    movie_keywords mk ON am.movie_title = mk.title
LEFT JOIN 
    movie_company_info mci ON am.movie_title = mci.title
WHERE 
    (am.notes_present > 0 OR am.role_count > 1)
    AND (mci.movie_count IS NULL OR mci.movie_count > 5)
ORDER BY 
    am.actor_name ASC, 
    am.movie_title ASC;
