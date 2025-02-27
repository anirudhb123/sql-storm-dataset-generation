WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        AVG(CASE WHEN p.info_type_id = 1 THEN LENGTH(p.info) ELSE NULL END) AS average_character_length
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        person_info p ON ca.person_id = p.person_id AND p.info_type_id IN (1, 2)
    GROUP BY 
        t.id, t.title, t.production_year, c.name
), RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.company_name,
    r.cast_count,
    r.average_character_length
FROM 
    RankedMovies r
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, r.cast_count DESC;

-- Additional Benchmark Queries
SELECT 
    k.keyword,
    COUNT(DISTINCT mk.movie_id) AS movie_count
FROM 
    keyword k
JOIN 
    movie_keyword mk ON k.id = mk.keyword_id
GROUP BY 
    k.keyword
HAVING 
    COUNT(DISTINCT mk.movie_id) > 10
ORDER BY 
    movie_count DESC;

SELECT 
    p.person_id,
    COALESCE(a.name, 'Unknown') AS name,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
    AVG(CASE 
            WHEN r.role = 'Lead' THEN ci.nr_order 
            ELSE NULL 
        END) AS average_lead_order
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    p.person_id, a.name
HAVING 
    roles_count > 5
ORDER BY 
    average_lead_order ASC;
