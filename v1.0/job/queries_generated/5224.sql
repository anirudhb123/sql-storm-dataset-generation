WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.company_id,
        cn.name AS company_name,
        GROUP_CONCAT(aka.name) AS alternate_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year, c.company_id, cn.name
),
GenreKeywords AS (
    SELECT 
        t.id AS movie_id,
        k.keyword 
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
PersonInfo AS (
    SELECT 
        p.person_id,
        p.info 
    FROM 
        person_info p
    JOIN 
        info_type it ON p.info_type_id = it.id
    WHERE 
        it.info = 'Biography'
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.alternate_names,
    GROUP_CONCAT(DISTINCT g.keyword) AS genres,
    GROUP_CONCAT(DISTINCT pi.info) AS biographies
FROM 
    MovieDetails md
LEFT JOIN 
    GenreKeywords g ON md.movie_id = g.movie_id
LEFT JOIN 
    PersonInfo pi ON md.company_id = pi.person_id
GROUP BY 
    md.movie_title, md.production_year, md.company_name, md.alternate_names
ORDER BY 
    md.production_year DESC, md.movie_title;
