WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ak.name AS aka_name,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT p.name) AS cast_members
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        name p ON ci.person_id = p.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, ak.name
),
InfoDetails AS (
    SELECT 
        md.title_id,
        md.movie_title,
        md.production_year,
        i.info AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.title_id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    WHERE 
        i.info IS NOT NULL
)
SELECT 
    title_id,
    movie_title,
    production_year,
    keywords,
    companies,
    cast_members,
    string_agg(additional_info, '; ') AS additional_infos
FROM 
    InfoDetails
GROUP BY 
    title_id, movie_title, production_year, keywords, companies, cast_members
ORDER BY 
    production_year DESC, movie_title;
