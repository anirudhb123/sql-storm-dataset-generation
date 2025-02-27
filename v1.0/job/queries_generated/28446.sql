WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    INNER JOIN 
        movie_companies AS mc ON t.movie_id = mc.movie_id
    INNER JOIN 
        company_name AS co ON mc.company_id = co.id
    INNER JOIN 
        company_type AS c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
PersonDetails AS (
    SELECT 
        ak.name AS person_name,
        STRING_AGG(DISTINCT p.info, '; ') AS person_info
    FROM 
        aka_name AS ak
    LEFT JOIN 
        person_info AS p ON ak.person_id = p.person_id
    GROUP BY 
        ak.id, ak.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_type,
    md.aka_names,
    md.keywords,
    pd.person_name,
    pd.person_info
FROM 
    MovieDetails AS md
LEFT JOIN 
    PersonDetails AS pd ON pd.person_name LIKE '%' || md.aka_names || '%'
ORDER BY 
    md.production_year DESC, md.movie_title;
