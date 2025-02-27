WITH movie_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_kind,
        a.name AS actor_name,
        p.gender AS actor_gender,
        p.md5sum AS actor_md5
    FROM 
        aka_title t
    INNER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        name p ON p.imdb_id = a.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%Action%'
),
gender_summary AS (
    SELECT 
        actor_gender,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        movie_titles
    GROUP BY 
        actor_gender
),
keyword_summary AS (
    SELECT 
        keyword,
        COUNT(DISTINCT title_id) AS movie_count
    FROM 
        movie_titles
    GROUP BY 
        keyword
)
SELECT 
    g.actor_gender,
    g.actor_count,
    k.keyword,
    k.movie_count
FROM 
    gender_summary g
FULL OUTER JOIN 
    keyword_summary k ON g.actor_gender IS NOT NULL AND k.keyword IS NOT NULL
ORDER BY 
    g.actor_count DESC NULLS LAST,
    k.movie_count DESC NULLS LAST;
