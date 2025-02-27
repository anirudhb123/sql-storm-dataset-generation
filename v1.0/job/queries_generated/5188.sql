WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        c.kind AS company_kind,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, c.kind
    ORDER BY 
        num_actors DESC, t.production_year DESC
    LIMIT 10
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_kind,
    rm.aliases,
    rm.num_actors,
    COUNT(mi.id) AS info_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info mi ON rm.title = mi.info 
LEFT JOIN 
    movie_keyword mk ON rm.title = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    rm.title, rm.production_year, rm.company_kind, rm.aliases, rm.num_actors
ORDER BY 
    rm.num_actors DESC;
