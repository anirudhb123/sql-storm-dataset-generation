
WITH MovieData AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name ASC) AS cast_names,
        STRING_AGG(DISTINCT co.name, ', ' ORDER BY co.name ASC) AS company_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id 
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%adventure%'
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
InfoTypeData AS (
    SELECT 
        m.id AS movie_id,
        it.info AS info_type_info
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        m.info ILIKE '%blockbuster%'
)
SELECT 
    md.title_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.cast_names,
    md.company_names,
    it.info_type_info
FROM 
    MovieData md
LEFT JOIN 
    InfoTypeData it ON md.title_id = it.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
