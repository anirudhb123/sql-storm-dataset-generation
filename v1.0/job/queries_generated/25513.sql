WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS company_names,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS person_name,
        GROUP_CONCAT(DISTINCT pinfo.info) AS person_info,
        GROUP_CONCAT(DISTINCT ci.note) AS cast_notes
    FROM 
        name p
    LEFT JOIN 
        person_info pinfo ON p.id = pinfo.person_id
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.company_names,
    md.roles,
    pd.person_id,
    pd.person_name,
    pd.person_info,
    pd.cast_notes
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;

This SQL query aggregates movie data with details about titles, alternate names, keywords, associated companies, and the roles of people involved in each movie, while also providing information on each person linked to the movie. The results are organized and sorted by the production year in descending order, followed by movie titles in ascending order.
