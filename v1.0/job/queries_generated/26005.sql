WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        cc.kind AS company_type,
        a.name AS actor_name,
        pn.info AS person_note
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type cc ON mc.company_type_id = cc.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        person_info pn ON a.person_id = pn.person_id 
                        AND pn.info_type_id = (SELECT id FROM info_type WHERE info = 'Note') 
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
),
ranking AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count,
        COUNT(DISTINCT movie_keyword) AS keyword_count,
        COUNT(DISTINCT company_name) AS company_count,
        MAX(production_year) AS latest_year
    FROM 
        movie_details
    GROUP BY 
        movie_id
)
SELECT 
    r.movie_id,
    md.title,
    r.actor_count,
    r.keyword_count,
    r.company_count,
    r.latest_year,
    ROW_NUMBER() OVER (ORDER BY r.actor_count DESC, r.keyword_count DESC) AS rank
FROM 
    ranking r
JOIN 
    aka_title md ON r.movie_id = md.id
WHERE 
    r.actor_count > 2
ORDER BY 
    r.rank;
