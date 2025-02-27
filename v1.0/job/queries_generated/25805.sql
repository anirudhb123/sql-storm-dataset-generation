WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    WHERE 
        a.production_year >= 2000
        AND k.keyword LIKE '%Action%'
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, k.keyword, c.name
    ORDER BY 
        cast_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rt.role AS main_role,
    COUNT(DISTINCT p.id) AS main_cast_count
FROM 
    RankedMovies rm
JOIN 
    complete_cast cc ON rm.movie_title = cc.subject_id
JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    name n ON ci.person_id = n.id
JOIN 
    person_info pi ON n.id = pi.person_id
WHERE 
    pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND rm.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
GROUP BY 
    rm.movie_title, rm.production_year, rt.role
ORDER BY 
    main_cast_count DESC;
