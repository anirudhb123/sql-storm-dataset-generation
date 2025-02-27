WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), movie_info_extended AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No Information') AS info,
        CASE 
            WHEN LENGTH(mi.info) < 20 THEN 'Short Info'
            ELSE 'Detailed Info'
        END AS info_type
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
), qualified_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mk.keyword_list,
        mie.info,
        mie.info_type
    FROM 
        ranked_movies rm
    JOIN 
        movie_keywords mk ON rm.movie_id = mk.movie_id
    JOIN 
        movie_info_extended mie ON rm.movie_id = mie.movie_id
    WHERE 
        rm.rank_per_year <= 5
        AND m.production_year >= 2000
)
SELECT 
    qm.title,
    qm.production_year,
    qm.keyword_list,
    qm.info,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    MAX(COALESCE(CASE WHEN ci.role_id IS NULL THEN 'Unknown' ELSE rt.role END, 'No Role')) AS predominant_role
FROM 
    qualified_movies qm
LEFT JOIN 
    complete_cast cc ON qm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
GROUP BY 
    qm.movie_id, qm.title, qm.production_year, qm.keyword_list, qm.info
ORDER BY 
    qm.production_year DESC, num_cast_members DESC;
