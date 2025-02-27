WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(k.keyword ORDER BY k.keyword) AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(DISTINCT CONCAT(it.info, ': ', mi.info) ORDER BY it.info) AS all_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles,
        COUNT(ci.person_id) AS number_of_cast_members
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movie_complete_info AS (
    SELECT 
        t.title,
        t.production_year,
        aa.all_keywords,
        ai.all_info,
        ac.roles,
        ac.number_of_cast_members
    FROM 
        title t
    LEFT JOIN 
        movie_keywords aa ON t.id = aa.movie_id
    LEFT JOIN 
        movie_info_details ai ON t.id = ai.movie_id
    LEFT JOIN 
        cast_roles ac ON t.id = ac.movie_id
)

SELECT 
    mci.title,
    mci.production_year,
    mci.all_keywords,
    mci.all_info,
    mci.roles,
    mci.number_of_cast_members
FROM 
    movie_complete_info mci
WHERE 
    mci.all_keywords LIKE '%thriller%' 
    AND mci.production_year >= 2000
ORDER BY 
    mci.production_year DESC, 
    mci.title ASC;
