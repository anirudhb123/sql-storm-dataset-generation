WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(k.id) AS keyword_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    HAVING 
        COUNT(k.id) > 0
),
TopRatedTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.kind_id,
        SUM(CASE 
                WHEN ci.role_id IN (SELECT id FROM role_type WHERE role = 'lead actor') THEN 1 
                ELSE 0 
            END) AS lead_actor_count
    FROM 
        RankedTitles AS rt
    JOIN 
        complete_cast AS cc ON rt.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    GROUP BY 
        rt.title, rt.production_year, rt.kind_id
    ORDER BY 
        lead_actor_count DESC
    LIMIT 10
)

SELECT 
    tt.title,
    tt.production_year,
    tt.kind_id,
    COUNT(DISTINCT ci.person_id) AS unique_cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopRatedTitles AS tt
JOIN 
    complete_cast AS cc ON tt.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword AS mk ON tt.id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
GROUP BY 
    tt.title, tt.production_year, tt.kind_id
ORDER BY 
    tt.production_year DESC, unique_cast_count DESC;
