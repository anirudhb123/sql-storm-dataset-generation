
WITH ranked_titles AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
cast_details AS (
    SELECT 
        ci.movie_id, 
        p.id AS person_id,
        p.name,
        rt.role AS role
    FROM 
        cast_info ci
    JOIN 
        name p ON ci.person_id = p.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_info_extended AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT ci.name, ', ') WITHIN GROUP (ORDER BY ci.name) AS cast,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_details ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 1980
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.rank,
    me.cast,
    me.keywords
FROM 
    ranked_titles r
JOIN 
    movie_info_extended me ON r.movie_id = me.movie_id
WHERE 
    r.rank = 1
ORDER BY 
    r.production_year DESC, 
    me.title;
