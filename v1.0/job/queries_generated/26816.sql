WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT info, ', ') AS info_summary
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
movie_company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
cast_characteristics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles_played
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    t.title,
    t.production_year,
    t.kind_id,
    mw.keyword AS movie_keyword,
    mis.info_summary,
    mcd.company_name,
    mcd.company_type,
    cc.total_cast,
    cc.roles_played
FROM 
    title t
JOIN 
    movie_keywords mw ON t.id = mw.movie_id
JOIN 
    movie_info_summary mis ON t.id = mis.movie_id
JOIN 
    movie_company_details mcd ON t.id = mcd.movie_id
JOIN 
    cast_characteristics cc ON t.id = cc.movie_id
WHERE 
    mw.keyword_rank <= 3
ORDER BY 
    t.production_year DESC, 
    t.title;
