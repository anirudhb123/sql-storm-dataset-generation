WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        pt.kind AS movie_genre,
        array_agg(DISTINCT an.name) AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        kind_type pt ON t.kind_id = pt.id
    GROUP BY 
        t.id, t.title, t.production_year, pt.kind
),
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
authoritative_movie_info AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.movie_genre,
        md.actors,
        cd.company_name,
        cd.company_type,
        cd.company_count
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    ami.movie_title,
    ami.production_year,
    ami.movie_keyword,
    ami.movie_genre,
    ami.actors,
    ami.company_name,
    ami.company_type,
    ami.company_count
FROM 
    authoritative_movie_info ami
WHERE 
    ama.production_year >= 2000
ORDER BY 
    ami.production_year DESC, ami.movie_title;
