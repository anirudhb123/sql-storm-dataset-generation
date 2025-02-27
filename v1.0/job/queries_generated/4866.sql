WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(cd.actor_name, ', ') AS cast,
    STRING_AGG(cd.actor_rank::text, ', ') AS actor_ranks,
    STRING_AGG(cd.actor_name || ' - Rank: ' || cd.actor_rank, '; ') AS detailed_cast,
    coalesce(cd2.company_name, 'Independent') AS production_company
FROM 
    movie_details md
LEFT JOIN 
    cast_details cd ON md.title_id = cd.movie_id
LEFT JOIN 
    company_details cd2 ON md.title_id = cd2.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM info_type it
        WHERE it.info = 'Awards'
        AND EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = md.title_id 
            AND mi.info_type_id = it.id
        )
    )
GROUP BY 
    md.title, md.production_year, cd2.company_name
ORDER BY 
    md.production_year DESC, md.title;
